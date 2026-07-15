///|
priv struct Parser {
  mut mode : Mode
  gullet : MacroExpander
  settings : Settings
  mut next_token : Token?
}

///|
priv enum AtomResult {
  EmitAtom(ParseNode)
  SkipAtom
}

///|
fn Parser::make(input : String, settings : Settings) -> Parser {
  {
    mode: Math,
    gullet: MacroExpander::make(input, settings),
    settings,
    next_token: None,
  }
}

///|
pub fn parse(
  input : String,
  settings? : Settings = Settings::default(),
) -> Array[ParseNode] raise ParseFailure {
  let parser = Parser::make(input, settings)
  parser.parse()
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
  if token.text == text {
    if consume {
      self.consume()
    }
  } else {
    raise ExpectedToken(expected=text, actual=Diagnostic::from_token(token))
  }
}

///|
fn Parser::parse(self : Parser) -> Array[ParseNode] raise ParseFailure {
  if !self.settings.global_group {
    self.gullet.begin_group()
  }
  let result : Result[Array[ParseNode], ParseFailure] = Ok(
    {
      let body = self.parse_expression(None)
      self.expect("EOF")
      body
    },
  ) catch {
    err => Err(err)
  }
  let close_result : Result[Unit, ParseFailure] = if !self.settings.global_group {
    Ok(self.gullet.end_group()) catch {
      err => Err(err)
    }
  } else {
    Ok(())
  }
  self.gullet.end_groups()
  match close_result {
    Err(err) => raise err
    Ok(_) =>
      match result {
        Err(err) => raise err
        Ok(body) => body
      }
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
  let result : Result[Array[ParseNode], ParseFailure] = Ok(
    {
      let body = self.parse_expression(Some("}"))
      self.expect("}")
      body
    },
  ) catch {
    err => Err(err)
  }
  self.next_token = old_token
  match result {
    Err(err) => raise err
    Ok(body) => body
  }
}

///|
fn Parser::parse_expression(
  self : Parser,
  break_on_token_text : String?,
) -> Array[ParseNode] raise ParseFailure {
  let body : Array[ParseNode] = []
  for ;; {
    if self.mode == Math {
      self.consume_spaces()
    }
    let token = self.fetch()
    if is_end_of_expression(token.text) {
      break self.finish_expression(body)
    } else if break_on_token_text is Some(stop) && token.text == stop {
      break self.finish_expression(body)
    } else {
      match self.parse_atom(break_on_token_text) {
        None => break self.finish_expression(body)
        Some(atom) =>
          match atom {
            SkipAtom => continue
            EmitAtom(node) => {
              body.push(node)
              continue
            }
          }
      }
    }
  }
}

///|
fn Parser::finish_expression(
  _self : Parser,
  body : Array[ParseNode],
) -> Array[ParseNode] {
  body
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
    if self.fetch().text == " " {
      self.consume()
      continue
    } else {
      break
    }
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
    Some(EmitAtom(base)) =>
      if self.mode == Text {
        Some(EmitAtom(base))
      } else {
        Some(EmitAtom(self.parse_scripts(base)))
      }
  }
}

///|
fn Parser::parse_scripts(
  self : Parser,
  base : ParseNode,
) -> ParseNode raise ParseFailure {
  let mut sup : ParseNode? = None
  let mut sub : ParseNode? = None
  for ;; {
    self.consume_spaces()
    let token = self.fetch()
    if token.text == "^" {
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
    self.consume()
    let group_end = if text == "{" { "}" } else { "\\endgroup" }
    self.gullet.begin_group()
    let body = self.parse_expression(Some(group_end))
    let last = self.fetch()
    self.expect(group_end)
    self.gullet.end_group()
    let loc = match (first_token.loc, last.loc) {
      (Some(start_loc), Some(end_loc)) =>
        Some(SourceLocation::range(start_loc, end_loc))
      _ => None
    }
    Some(
      EmitAtom(
        OrdGroup(mode=self.mode, loc~, body~, semisimple=text == "\\begingroup"),
      ),
    )
  } else {
    match self.parse_function(break_on_token_text, Some(name)) {
      Some(result) => Some(result)
      None =>
        match self.parse_symbol() {
          Some(node) => Some(EmitAtom(node))
          None =>
            if text.length() > 0 && text[0] == '\\' {
              if self.settings.throw_on_error {
                raise UndefinedControlSequence(name=text, loc=first_token.loc)
              } else {
                self.consume()
                Some(
                  EmitAtom(
                    format_unsupported_command(self.mode, self.settings, text),
                  ),
                )
              }
            } else {
              None
            }
        }
    }
  }
}

///|
fn Parser::parse_function(
  self : Parser,
  break_on_token_text : String?,
  name : String?,
) -> AtomResult? raise ParseFailure {
  let token = self.fetch()
  match lookup_function(token.text) {
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
    parser: self,
    token,
    break_on_token_text,
  }
  match lookup_function(func_name) {
    None => raise MissingFunctionHandler(func_name~, loc=None)
    Some(spec) =>
      match spec.handler {
        None => raise MissingFunctionHandler(func_name~, loc=None)
        Some(handler) => handler(context, args, opt_args)
      }
  }
}

///|
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
    let normalized = normalize_unicode_symbol(self.mode, original_text)
    let mark_start = trailing_combining_mark_start(normalized)
    let text = match mark_start {
      Some(start) => normalized.unsafe_substring(start=0, end=start)
      None => normalized
    }
    let text = match mark_start {
      Some(_) if text == "i" => "ı"
      Some(_) if text == "j" => "ȷ"
      _ => text
    }
    match make_base_symbol_node(self.mode, text, token.loc) {
      None => None
      Some(base) => {
        self.consume()
        match mark_start {
          None => Some(base)
          Some(start) =>
            Some(
              apply_unicode_accents(
                self.mode,
                token.loc,
                base,
                normalized.unsafe_substring(start~, end=normalized.length()),
              ),
            )
        }
      }
    }
  }
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
fn make_base_symbol_node(
  mode : Mode,
  text : String,
  loc : SourceLocation?,
) -> ParseNode? {
  match lookup_symbol(mode, text) {
    Some(spec) => Some(make_symbol_node(mode, text, loc, spec))
    None =>
      if text.length() > 0 && text[0] >= 0x80 {
        Some(TextOrd(mode=Text, loc~, text~))
      } else {
        None
      }
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
    let label = match unicode_accent_command(mode, accent_text) {
      Some(command) => command
      None =>
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
  let body : Array[ParseNode] = []
  for _, ch in text {
    body.push(TextOrd(mode=Text, loc=None, text=String::from_array([ch])))
  }
  Color(mode~, color=settings.error_color, body~)
}

///|
