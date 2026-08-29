///|
priv struct Parser {
  mut mode : Mode
  gullet : MacroExpander
  settings : Settings
  function_registry : FunctionRegistry
  environment_registry : EnvironmentRegistry
  mut next_token : Token?
  mut leftright_depth : Int
}

///|
priv enum AtomResult {
  EmitAtom(ParseNode)
  SkipAtom
}

///|
fn Parser::make(
  input : String,
  settings : Settings,
  extra_specs? : Array[FunctionSpec] = [],
  extra_env_specs? : Array[EnvironmentSpec] = [],
) -> Parser {
  let registry = build_function_registry(extra_specs)
  {
    mode: Math,
    gullet: MacroExpander::make(
      input,
      settings,
      report_nonstrict=(error_code, error_message) => {
        settings.report_nonstrict(error_code, error_message, None)
      },
      command_status=name => {
        match registry.get(name) {
          Some(spec) =>
            if spec.is_expandable() {
              ExternalExpandable
            } else {
              ExternalUnexpandable
            }
          None =>
            if is_registered_symbol(name) {
              ExternalUnexpandable
            } else {
              ExternalUndefined
            }
        }
      },
    ),
    settings,
    function_registry: registry,
    environment_registry: build_environment_registry(extra_env_specs),
    next_token: None,
    leftright_depth: 0,
  }
}

///|
pub fn parse(
  input : String,
  settings? : Settings = Default::default(),
  extra_specs? : Array[FunctionSpec] = [],
  extra_env_specs? : Array[EnvironmentSpec] = [],
) -> Array[ParseNode] raise ParseFailure {
  let parser = Parser::make(input, settings, extra_specs~, extra_env_specs~)
  parser.gullet.macros.set("\\df@tag", None)
  let body = parser.parse()
  let body = if parser.gullet.macros.get("\\df@tag") is Some(_) {
    guard settings.display_mode else {
      raise InvalidArgument(
        message="\\tag works only in display equations",
        loc=None,
      )
    }
    [Tag(mode=Text, body~, tag=parser.subparse([Token::make("\\df@tag")]))]
  } else {
    body
  }
  parser.gullet.macros.set("\\current@color", None)
  parser.gullet.macros.set("\\color", None)

  guard settings.display_mode else { body }
  [Styling(mode=Math, body~, style=DisplayStyle, reset_font=true)]
}

///|
fn Parser::fetch(self : Parser) -> Token raise ParseFailure {
  match self.next_token {
    Some(token) => token
    None => {
      let token = self.gullet.expand_next_token()
      self.next_token = Some(token)
      token
    }
  }
}

///|
fn Parser::consume(self : Parser) -> Unit {
  self.next_token = None
}

///|
fn Parser::expect(
  self : Parser,
  text : String,
  consume? : Bool = true,
) -> Unit raise ParseFailure {
  let token = self.fetch()
  guard token.text == text else {
    raise ExpectedToken(expected=text, actual=Diagnostic::from_token(token))
  }
  if consume {
    self.consume()
  }
}

///|
fn Parser::parse(self : Parser) -> Array[ParseNode] raise ParseFailure {
  if !self.settings.global_group {
    self.gullet.begin_group()
  }
  if self.settings.color_is_text_color {
    self.gullet.macros.set(
      "\\color",
      Some(MacroDefinition::text("\\textcolor")),
    )
  }
  let result : Result[Array[ParseNode], ParseFailure] = capture_parse_result(() => {
    let body = self.parse_expression(false, None)
    self.expect("EOF")
    body
  })
  let close_result : Result[Unit, ParseFailure] = capture_parse_result(() => {
    guard !self.settings.global_group else { () }
    self.gullet.end_group()
  })
  self.gullet.end_groups()
  if self.settings.global_group {
    self.persist_user_macros()
  }
  unwrap_captured(close_result, result)
}

///|
/// Copies the macros defined during parsing back into the caller's macro
/// store, so `\newcommand` in a `global_group` parse survives the parse.
fn Parser::persist_user_macros(self : Parser) -> Unit {
  match self.settings.macro_store {
    Some(macros) => {
      let user_entries = self.gullet.macros.get_user_entries()
      for name, definition in user_entries {
        macros.0[name] = definition
      }
    }
    None => ()
  }
}

///|
fn Parser::subparse(
  self : Parser,
  tokens : Array[Token],
) -> Array[ParseNode] raise ParseFailure {
  let old_token = self.next_token
  self.consume()
  self.gullet.push_token(Token::make("}"))
  self.gullet.push_tokens(tokens)
  defer {
    self.next_token = old_token
  }
  let body = self.parse_expression(false, Some("}"))
  self.expect("}")
  body
}

///|
fn Parser::parse_math_mode(
  self : Parser,
  close : String,
) -> Array[ParseNode] raise ParseFailure {
  let outer_mode = self.mode
  self.switch_mode(Math)
  defer self.switch_mode(outer_mode)
  let body = self.parse_expression(false, Some(close))
  self.expect(close)
  body
}

///|
fn Parser::current_color(self : Parser) -> String? raise ParseFailure {
  match self.gullet.macros.get("\\current@color") {
    None => None
    Some(Text(color)) => Some(color)
    Some(Expansion(_)) =>
      raise InvalidArgument(
        message="\\current@color set to non-string in \\right",
        loc=None,
      )
  }
}

///|
fn Parser::parse_left_right(
  self : Parser,
  left : String,
) -> ParseNode raise ParseFailure {
  self.leftright_depth = self.leftright_depth + 1
  defer {
    self.leftright_depth = self.leftright_depth - 1
  }
  let body = self.parse_expression(false, None)
  self.expect("\\right", consume=false)
  guard self.parse_function(None, None)
    is Some(EmitAtom(LeftRightRight(delim=right, color~, ..))) else {
    raise InternalInvariant(
      message="\\right did not produce a closing delimiter",
    )
  }
  LeftRight(mode=self.mode, body~, left~, right~, right_color=color)
}

///|
fn Parser::parse_expression(
  self : Parser,
  break_on_infix : Bool,
  break_on_token_text : String?,
) -> Array[ParseNode] raise ParseFailure {
  let body : Array[ParseNode] = []
  for ;; {
    if self.mode == Math {
      self.consume_spaces()
    }
    let token = self.fetch()
    if self.should_break_expression(
        token.text,
        break_on_infix,
        break_on_token_text,
      ) {
      break self.finish_expression(body)
    }
    match self.parse_atom(break_on_token_text) {
      None => break self.finish_expression(body)
      Some(SkipAtom) => continue
      Some(EmitAtom(node)) => {
        body.push(node)
        continue
      }
    }
  }
}

///|
/// True when the token ends the current expression: a group- or
/// environment-ending token, the caller's explicit stop token, or an infix
/// function (`\over`, `\atop`, ...) when the caller breaks on those.
fn Parser::should_break_expression(
  self : Parser,
  text : String,
  break_on_infix : Bool,
  break_on_token_text : String?,
) -> Bool {
  is_end_of_expression(text) ||
  (break_on_token_text is Some(stop) && text == stop) ||
  (
    break_on_infix &&
    self.function_registry.get(text) is Some(spec) &&
    spec.infix
  )
}

///|
fn Parser::finish_expression(
  self : Parser,
  body : Array[ParseNode],
) -> Array[ParseNode] raise ParseFailure {
  let normalized = if self.mode == Text {
    form_text_ligatures(body)
  } else {
    body
  }
  self.handle_infix_nodes(normalized)
}

///|
fn is_end_of_expression(text : String) -> Bool {
  text == "}" ||
  text == "\\endgroup" ||
  text == "\\end" ||
  text == "\\right" ||
  text == "&"
}

///|
fn Parser::consume_spaces(self : Parser) -> Unit raise ParseFailure {
  for ;; {
    guard self.fetch().text == " " else { break }
    self.consume()
  }
}

///|
fn Parser::parse_atom(
  self : Parser,
  break_on_token_text : String?,
) -> AtomResult? raise ParseFailure {
  match self.parse_group("atom", break_on_token_text) {
    None => None
    Some(SkipAtom) => Some(SkipAtom)
    Some(EmitAtom(Internal(..))) => Some(SkipAtom)
    Some(EmitAtom(base)) if self.mode == Text => Some(EmitAtom(base))
    Some(EmitAtom(base)) => Some(EmitAtom(self.parse_scripts(base)))
  }
}

///|
fn Parser::parse_scripts(
  self : Parser,
  base : ParseNode,
) -> ParseNode raise ParseFailure {
  let mut base = base
  let mut sup : ParseNode? = None
  let mut sub : ParseNode? = None
  for ;; {
    self.consume_spaces()
    let token = self.fetch()
    if token.text == "\\limits" || token.text == "\\nolimits" {
      base = set_limits(base, token.text == "\\limits", token.loc)
      self.consume()
      continue
    } else if token.text == "^" {
      if sup is Some(_) {
        raise DoubleSuperscript(loc=token.loc)
      }
      sup = Some(self.handle_sup_subscript("superscript"))
      continue
    } else if token.text == "_" {
      if sub is Some(_) {
        raise DoubleSubscript(loc=token.loc)
      }
      sub = Some(self.handle_sup_subscript("subscript"))
      continue
    } else if token.text == "'" {
      if sup is Some(_) {
        raise DoubleSuperscript(loc=token.loc)
      }
      sup = Some(self.parse_prime_run())
      continue
    } else {
      match lookup_unicode_script(token.text) {
        None => break make_supsub_or_base(self.mode, base, sup, sub)
        Some(first_script) => {
          let (is_subscript, script_tokens) = self.consume_unicode_script_run(
            first_script,
          )
          let body = self.subparse(script_tokens)
          let group = OrdGroup(mode=Math, loc=None, body~, semisimple=false)
          if is_subscript {
            sub = Some(group)
          } else {
            sup = Some(group)
          }
          continue
        }
      }
    }
  }
}

///|
/// Rewrites an operator node so that its scripts are drawn as limits above
/// and below. Only `Op` and `\operatorname*` nodes accept limit controls.
fn set_limits(
  base : ParseNode,
  limits : Bool,
  loc : SourceLocation?,
) -> ParseNode raise ParseFailure {
  match base {
    Op(mode~, parent_is_sup_sub~, suppress_base_shift~, content~, ..) =>
      Op(
        mode~,
        limits~,
        always_handle_sup_sub=true,
        parent_is_sup_sub~,
        suppress_base_shift~,
        content~,
      )
    OperatorName(
      mode~,
      body~,
      always_handle_sup_sub=true,
      parent_is_sup_sub~,
      ..
    ) =>
      OperatorName(
        mode~,
        body~,
        always_handle_sup_sub=true,
        limits~,
        parent_is_sup_sub~,
      )
    _ =>
      raise InvalidArgument(
        message="Limit controls must follow a math operator",
        loc~,
      )
  }
}

///|
/// Consumes a run of consecutive `'` primes (followed by an optional `^`
/// script) and returns them as a single `OrdGroup` superscript.
fn Parser::parse_prime_run(self : Parser) -> ParseNode raise ParseFailure {
  let primes : Array[ParseNode] = []
  while self.fetch().text == "'" {
    let prime_token = self.fetch()
    primes.push(TextOrd(mode=self.mode, loc=prime_token.loc, text="\\prime"))
    self.consume()
  }
  if self.fetch().text == "^" {
    primes.push(self.handle_sup_subscript("superscript"))
  }
  OrdGroup(mode=self.mode, loc=None, body=primes, semisimple=false)
}

///|
fn Parser::consume_unicode_script_run(
  self : Parser,
  first : UnicodeScript,
) -> (Bool, Array[Token]) raise ParseFailure {
  let is_subscript = first.kind is UnicodeSubscript
  let tokens : Array[Token] = [Token::make(first.replacement)]
  self.consume()
  for ;; {
    let next = self.fetch()
    match lookup_unicode_script(next.text) {
      Some(script) if (script.kind is UnicodeSubscript) == is_subscript => {
        tokens.push(Token::make(script.replacement))
        self.consume()
        continue
      }
      _ => {
        tokens.rev_in_place()
        break (is_subscript, tokens)
      }
    }
  }
}

///|
fn make_supsub_or_base(
  mode : Mode,
  base : ParseNode,
  sup : ParseNode?,
  sub : ParseNode?,
) -> ParseNode {
  match (sup, sub) {
    (None, None) => base
    _ => SupSub(mode~, base=Some(base), sup~, sub~)
  }
}

///|
fn Parser::handle_sup_subscript(
  self : Parser,
  name : String,
) -> ParseNode raise ParseFailure {
  let token = self.fetch()
  self.consume()
  self.consume_spaces()
  for ;; {
    match self.parse_group(name, None) {
      Some(EmitAtom(Internal(..))) | Some(SkipAtom) => continue
      Some(EmitAtom(group)) => break group
      None => raise ExpectedGroupAfter(symbol=token.text, loc=token.loc)
    }
  }
}

///|
fn Parser::parse_group(
  self : Parser,
  name : String,
  break_on_token_text : String?,
) -> AtomResult? raise ParseFailure {
  let first_token = self.fetch()
  let text = first_token.text
  if text == "{" || text == "\\begingroup" {
    Some(EmitAtom(self.parse_group_body(first_token, text)))
  } else {
    match self.parse_function(break_on_token_text, Some(name)) {
      Some(result) => Some(result)
      None =>
        match self.parse_symbol() {
          Some(node) => Some(EmitAtom(node))
          None => self.handle_undefined_control(first_token)
        }
    }
  }
}

///|
/// Parses the body of a `{...}` or `\begingroup...\endgroup` group into an
/// `OrdGroup` node whose source span covers the whole group.
fn Parser::parse_group_body(
  self : Parser,
  first_token : Token,
  text : String,
) -> ParseNode raise ParseFailure {
  self.consume()
  let group_end = if text == "{" { "}" } else { "\\endgroup" }
  self.gullet.begin_group()
  let body = self.parse_expression(false, Some(group_end))
  let last = self.fetch()
  self.expect(group_end)
  self.gullet.end_group()
  let loc = if first_token.loc is Some(start_loc) && last.loc is Some(end_loc) {
    Some(SourceLocation::range(start_loc, end_loc))
  } else {
    None
  }
  OrdGroup(mode=self.mode, loc~, body~, semisimple=text == "\\begingroup")
}

///|
/// Reports a token that parsed neither as a function nor as a symbol: a
/// backslash command that is not implicitly recognized is an undefined
/// control sequence (raised when `throw_on_error`, otherwise rendered as an
/// `error_color` span); anything else is not a group at all.
fn Parser::handle_undefined_control(
  self : Parser,
  token : Token,
) -> AtomResult? raise ParseFailure {
  let text = token.text
  guard is_undefined_control_sequence(text) else { None }
  guard self.settings.throw_on_error else {
    self.consume()
    Some(EmitAtom(format_unsupported_command(self.mode, self.settings, text)))
  }
  raise UndefinedControlSequence(name=text, loc=token.loc)
}

///|
fn is_undefined_control_sequence(text : String) -> Bool {
  text.length() > 0 && text[0] == '\\' && !is_implicit_command(text)
}

///|
fn Parser::parse_function(
  self : Parser,
  break_on_token_text : String?,
  name : String?,
) -> AtomResult? raise ParseFailure {
  let token = self.fetch()
  match self.function_registry.get(token.text) {
    None => None
    Some(func_data) => {
      self.consume()
      if name is Some(context_name) &&
        context_name != "atom" &&
        !func_data.allowed_in_argument {
        raise FunctionNotAllowed(
          func_name=token.text,
          context=context_name,
          loc=token.loc,
        )
      } else if self.mode == Text && !func_data.allowed_in_text {
        raise FunctionNotAllowed(
          func_name=token.text,
          context="text mode",
          loc=token.loc,
        )
      } else if self.mode == Math && !func_data.allowed_in_math {
        raise FunctionNotAllowed(
          func_name=token.text,
          context="math mode",
          loc=token.loc,
        )
      } else {
        let (args, opt_args) = self.parse_arguments(token.text, func_data)
        Some(
          EmitAtom(
            self.call_function(
              token.text,
              args,
              opt_args,
              Some(token),
              break_on_token_text,
            ),
          ),
        )
      }
    }
  }
}

///|
fn Parser::call_function(
  self : Parser,
  func_name : String,
  args : Array[ParseNode],
  opt_args : Array[ParseNode?],
  token : Token?,
  break_on_token_text : String?,
) -> ParseNode raise ParseFailure {
  let context : FunctionContext = {
    func_name,
    mode: self.mode,
    token,
    break_on_token_text,
    set_macro: (name, definition) => self.gullet.macros.set(name, definition),
    report_nonstrict: (error_code, error_message) => {
      self.settings.report_nonstrict(error_code, error_message, token)
    },
    is_trusted: context => self.settings.is_trusted(context),
    parse_optional_size: () => {
      if self.gullet.future().text != "[" {
        None
      } else {
        match self.parse_size_group(true) {
          Some(Size(value~, ..)) => Some(value)
          _ => raise InternalInvariant(message="Expected optional size")
        }
      }
    },
    display_mode: self.settings.display_mode,
    use_strict_behavior: (error_code, error_message) => {
      self.settings.use_strict_behavior(error_code, error_message, token)
    },
    current_color: () => self.current_color(),
    in_left_right: () => self.leftright_depth > 0,
    parse_expression: (break_on_infix, break_on_token_text) => {
      self.parse_expression(break_on_infix, break_on_token_text)
    },
    parse_math_mode: close => self.parse_math_mode(close),
    parse_left_right: left => self.parse_left_right(left),
    pop_token: () => self.gullet.pop_token(),
    future_token: () => self.gullet.future(),
    push_token: value => self.gullet.push_token(value),
    consume_spaces: () => self.gullet.consume_spaces(),
    consume_macro_arg: () => self.gullet.consume_arg(None).tokens,
    expand_tokens: values => self.gullet.expand_tokens(values),
    get_macro: name => self.gullet.macros.get(name),
    set_macro_definition: (name, definition, global) => {
      self.gullet.macros.set(name, Some(definition), global~)
    },
    is_expandable: name => self.gullet.is_expandable(name),
    parse_prefixed_function: name => self.parse_prefixed_function(name),
    parse_environment: name => self.parse_environment(name),
  }
  guard self.function_registry.get(func_name) is Some(spec) else {
    raise MissingFunctionHandler(func_name~, loc=None)
  }
  guard spec.handler is Some(handler) else {
    raise MissingFunctionHandler(func_name~, loc=None)
  }
  handler(context, args, opt_args)
}

///|
fn Parser::parse_environment(
  self : Parser,
  name : String,
) -> ParseNode raise ParseFailure {
  guard self.environment_registry.get(name) is Some(spec) else {
    raise InvalidArgument(message="No such environment: \{name}", loc=None)
  }
  let arguments = FunctionSpec::make(
    [],
    spec.num_args,
    num_optional_args=spec.num_optional_args,
    arg_types=spec.arg_types,
  )
  let (args, opt_args) = self.parse_arguments("\\begin{\{name}}", arguments)
  let context : EnvironmentContext = {
    mode: self.mode,
    display_mode: self.settings.display_mode,
    leqno: self.settings.leqno,
    env_name: name,
    parse_array: options => self.parse_array_environment(options),
    parse_matrix_alignment: () => self.parse_matrix_alignment(),
    parse_cd: () => self.parse_cd_environment(),
  }
  let result = (spec.handler)(context, args, opt_args)
  self.expect("\\end", consume=false)
  match self.parse_function(None, None) {
    Some(EmitAtom(EnvironmentEnd(name=end_name, ..))) if end_name == name =>
      result
    Some(EmitAtom(EnvironmentEnd(name=end_name, ..))) =>
      raise InvalidArgument(
        message="Mismatch: \\begin{\{name}} matched by \\end{\{end_name}}",
        loc=None,
      )
    _ => raise InternalInvariant(message="Expected environment end")
  }
}

///|
fn Parser::parse_matrix_alignment(self : Parser) -> String? raise ParseFailure {
  self.consume_spaces()
  guard self.fetch().text == "[" else { None }
  self.consume()
  self.consume_spaces()
  let token = self.fetch()
  guard token.text == "l" || token.text == "c" || token.text == "r" else {
    raise InvalidArgument(message="Expected l or c or r", loc=token.loc)
  }
  self.consume()
  self.consume_spaces()
  self.expect("]")
  Some(token.text)
}

///|
fn Parser::parse_prefixed_function(
  self : Parser,
  name : String,
) -> ParseNode raise ParseFailure {
  self.gullet.push_token(Token::make(name))
  guard self.parse_function(None, None) is Some(EmitAtom(node)) else {
    raise InternalInvariant(message="Expected function after macro prefix")
  }
  node
}

///|
/// Parses a single token into a symbol node: structural tokens (`^`, `_`,
/// braces, `&`, EOF) are not symbols, verb tokens are parsed as `Verb` nodes,
/// and everything else goes through `parse_symbol_text`.
fn Parser::parse_symbol(self : Parser) -> ParseNode? raise ParseFailure {
  let token = self.fetch()
  let original_text = token.text
  if original_text == "EOF" ||
    original_text == "^" ||
    original_text == "_" ||
    original_text == "{" ||
    original_text == "}" ||
    original_text == "&" {
    None
  } else if is_verb_token(original_text) {
    self.consume()
    Some(parse_verb_token(original_text))
  } else {
    self.parse_symbol_text(
      token,
      original_text,
      normalize_unicode_symbol(self.mode, original_text),
    )
  }
}

///|
/// Parses a non-verb token as a symbol: normalizes it, splits off trailing
/// combining marks (with the `i`/`j` -> dotless forms), looks it up in the
/// symbol registry, and reports strict-mode warnings for text characters in
/// math mode. Unrecognized non-ASCII text becomes a `TextOrd` node.
fn Parser::parse_symbol_text(
  self : Parser,
  token : Token,
  original_text : String,
  normalized : String,
) -> ParseNode? raise ParseFailure {
  // KaTeX Parser.ts: accented Unicode text decomposition in math mode
  if self.mode == Math && normalized != original_text {
    self.settings.report_nonstrict(
      "unicodeTextInMathMode",
      "Accented Unicode text character \"\{original_text[0]}\" used in math mode",
      Some(token),
    )
  }
  let (text, marks) = split_combining_marks(normalized)
  match lookup_symbol(self.mode, text) {
    Some(spec) => {
      // KaTeX Parser.ts: Latin-1 fallback letters (Ð Þ þ) in math mode
      if self.mode == Math && is_extra_latin(text) {
        self.settings.report_nonstrict(
          "unicodeTextInMathMode",
          "Latin-1/Unicode text character \"\{text[0]}\" used in math mode",
          Some(token),
        )
      }
      self.consume()
      let base = make_symbol_node(self.mode, text, token.loc, spec)
      match marks {
        None => Some(base)
        Some(accents) =>
          Some(apply_unicode_accents(self.mode, token.loc, base, accents))
      }
    }
    None if is_non_ascii(text) => {
      // KaTeX Parser.ts: unrecognized Unicode characters
      if !supported_codepoint(text[0].to_int()) {
        self.settings.report_nonstrict(
          "unknownSymbol",
          "Unrecognized Unicode character \"\{text[0]}\" (\{text[0].to_int()})",
          Some(token),
        )
      } else if self.mode == Math {
        self.settings.report_nonstrict(
          "unicodeTextInMathMode",
          "Unicode text character \"\{text[0]}\" used in math mode",
          Some(token),
        )
      }
      self.consume()
      Some(TextOrd(mode=Text, loc=token.loc, text~))
    }
    None => None
  }
}

///|
/// Splits a normalized token text into a base without trailing combining
/// marks and the marks themselves. A base of `i`/`j` becomes its dotless form
/// (`ı`/`ȷ`) since the combining mark would otherwise render on the dot.
fn split_combining_marks(normalized : String) -> (String, String?) {
  match trailing_combining_mark_start(normalized) {
    None => (normalized, None)
    Some(start) => {
      let base = normalized.unsafe_substring(start=0, end=start)
      let base = if base == "i" {
        "ı"
      } else if base == "j" {
        "ȷ"
      } else {
        base
      }
      (base, Some(normalized.unsafe_substring(start~, end=normalized.length())))
    }
  }
}

///|
fn is_non_ascii(text : String) -> Bool {
  text.length() > 0 && text[0] >= 0x80
}

///|
fn is_verb_token(text : String) -> Bool {
  text.length() > 5 &&
  starts_with_at(text, 0, "\\verb") &&
  !is_ascii_alphabetic(text[5])
}

///|
fn parse_verb_token(text : String) -> ParseNode raise ParseFailure {
  let raw_argument = text.unsafe_substring(start=5, end=text.length())
  let star = raw_argument.length() > 0 && raw_argument[0] == '*'
  let argument = if star {
    raw_argument.unsafe_substring(start=1, end=raw_argument.length())
  } else {
    raw_argument
  }
  if argument.length() < 2 || argument[0] != argument[argument.length() - 1] {
    raise InternalInvariant(
      message="\\verb assertion failed -- please report what input caused this bug",
    )
  } else {
    Verb(
      mode=Text,
      loc=None,
      body=argument.unsafe_substring(start=1, end=argument.length() - 1),
      star~,
    )
  }
}

///|
/// True when the text is one of the Latin-1 letters KaTeX registers as
/// fallback symbols (Ð Þ þ, symbols.ts extraLatin).
fn is_extra_latin(text : String) -> Bool {
  match text.length() {
    0 => false
    _ => text[0] == 'Ð' || text[0] == 'Þ' || text[0] == 'þ'
  }
}

///|
fn apply_unicode_accents(
  mode : Mode,
  loc : SourceLocation?,
  base : ParseNode,
  accents : String,
) -> ParseNode raise ParseFailure {
  let mut result = base
  for accent in accents {
    let accent_text = String::from_array([accent])
    guard unicode_accent_command(mode, accent_text) is Some(label) else {
      raise InvalidArgument(message="Unknown accent ' \{accent_text}'", loc~)
    }
    result = Accent(
      mode~,
      loc~,
      label~,
      is_stretchy=false,
      is_shifty=true,
      base=result,
    )
  }
  result
}

///|
fn make_symbol_node(
  mode : Mode,
  text : String,
  loc : SourceLocation?,
  spec : SymbolSpec,
) -> ParseNode {
  match spec.group {
    AccentTokenGroup => AccentToken(mode~, loc~, text~)
    BinaryGroup => Atom(mode~, loc~, family=Mbin, text~)
    CloseGroup => Atom(mode~, loc~, family=Mclose, text~)
    InnerGroup => Atom(mode~, loc~, family=Minner, text~)
    MathOrdGroup => MathOrd(mode~, loc~, text~)
    OperatorTokenGroup => OperatorToken(mode~, loc~, text~)
    OpenGroup => Atom(mode~, loc~, family=Mopen, text~)
    PunctuationGroup => Atom(mode~, loc~, family=Mpunct, text~)
    RelationGroup => Atom(mode~, loc~, family=Mrel, text~)
    SpacingGroup => Spacing(mode~, loc~, text~)
    TextOrdGroup => TextOrd(mode~, loc~, text~)
  }
}

///|
fn format_unsupported_command(
  mode : Mode,
  settings : Settings,
  text : String,
) -> ParseNode {
  let body = text
    .to_array()
    .map(ch => TextOrd(mode=Text, loc=None, text=String::from_array([ch])))
  Color(mode~, color=settings.error_color, body~)
}
