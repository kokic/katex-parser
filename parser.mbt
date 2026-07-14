///|
priv struct Parser {
  mode : Mode
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
) -> ParseResult[Array[ParseNode]] {
  let parser = Parser::make(input, settings)
  parser.parse()
}

///|
fn Parser::fetch(self : Parser) -> ParseResult[Token] {
  match self.next_token {
    Some(token) => Ok(token)
    None =>
      match self.gullet.expand_next_token() {
        Ok(token) => {
          self.next_token = Some(token)
          Ok(token)
        }
        Err(err) => Err(err)
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
) -> ParseResult[Unit] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(token) =>
      if token.text == text {
        if consume {
          self.consume()
        }
        Ok(())
      } else {
        Err(ExpectedToken(expected=text, actual=Diagnostic::from_token(token)))
      }
  }
}

///|
fn Parser::parse(self : Parser) -> ParseResult[Array[ParseNode]] {
  if !self.settings.global_group {
    self.gullet.begin_group()
  }
  let parsed = self.parse_expression(None)
  let result = match parsed {
    Err(err) => Err(err)
    Ok(body) =>
      match self.expect("EOF") {
        Err(err) => Err(err)
        Ok(_) => Ok(body)
      }
  }
  let close_result = if !self.settings.global_group {
    self.gullet.end_group()
  } else {
    Ok(())
  }
  self.gullet.end_groups()
  match close_result {
    Err(err) => Err(err)
    Ok(_) => result
  }
}

///|
fn Parser::subparse(
  self : Parser,
  tokens : Array[Token],
) -> ParseResult[Array[ParseNode]] {
  let old_token = self.next_token
  self.consume()
  self.gullet.push_token(Token::make("}"))
  self.gullet.push_tokens(tokens)
  let parsed = self.parse_expression(Some("}"))
  let result = match parsed {
    Err(err) => Err(err)
    Ok(body) =>
      match self.expect("}") {
        Err(err) => Err(err)
        Ok(_) => Ok(body)
      }
  }
  self.next_token = old_token
  result
}

///|
fn Parser::parse_expression(
  self : Parser,
  break_on_token_text : String?,
) -> ParseResult[Array[ParseNode]] {
  let body : Array[ParseNode] = []
  for ;; {
    if self.mode == Math {
      match self.consume_spaces() {
        Err(err) => break Err(err)
        Ok(_) => ()
      }
    }
    match self.fetch() {
      Err(err) => break Err(err)
      Ok(token) =>
        if is_end_of_expression(token.text) {
          break Ok(self.finish_expression(body))
        } else if break_on_token_text is Some(stop) && token.text == stop {
          break Ok(self.finish_expression(body))
        } else {
          match self.parse_atom() {
            Err(err) => break Err(err)
            Ok(None) => break Ok(self.finish_expression(body))
            Ok(Some(atom)) =>
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
fn Parser::consume_spaces(self : Parser) -> ParseResult[Unit] {
  for ;; {
    match self.fetch() {
      Err(err) => break Err(err)
      Ok(token) =>
        if token.text == " " {
          self.consume()
          continue
        } else {
          break Ok(())
        }
    }
  }
}

///|
fn Parser::parse_atom(self : Parser) -> ParseResult[AtomResult?] {
  match self.parse_group("atom") {
    Err(err) => Err(err)
    Ok(None) => Ok(None)
    Ok(Some(SkipAtom)) => Ok(Some(SkipAtom))
    Ok(Some(EmitAtom(base))) =>
      if self.mode == Text {
        Ok(Some(EmitAtom(base)))
      } else {
        match self.parse_scripts(base) {
          Err(err) => Err(err)
          Ok(None) => Ok(None)
          Ok(Some(node)) => Ok(Some(EmitAtom(node)))
        }
      }
  }
}

///|
fn Parser::parse_scripts(
  self : Parser,
  base : ParseNode,
) -> ParseResult[ParseNode?] {
  let mut sup : ParseNode? = None
  let mut sub : ParseNode? = None
  for ;; {
    match self.consume_spaces() {
      Err(err) => break Err(err)
      Ok(_) => ()
    }
    match self.fetch() {
      Err(err) => break Err(err)
      Ok(token) =>
        if token.text == "^" {
          if sup is Some(_) {
            break Err(DoubleSuperscript(loc=token.loc))
          }
          match self.handle_sup_subscript("superscript") {
            Err(err) => break Err(err)
            Ok(group) => {
              sup = Some(group)
              continue
            }
          }
        } else if token.text == "_" {
          if sub is Some(_) {
            break Err(DoubleSubscript(loc=token.loc))
          }
          match self.handle_sup_subscript("subscript") {
            Err(err) => break Err(err)
            Ok(group) => {
              sub = Some(group)
              continue
            }
          }
        } else {
          match lookup_unicode_script(token.text) {
            None =>
              break Ok(Some(make_supsub_or_base(self.mode, base, sup, sub)))
            Some(first_script) => {
              let (is_subscript, script_tokens) = match
                self.consume_unicode_script_run(first_script) {
                Err(err) => break Err(err)
                Ok(value) => value
              }
              let body = match self.subparse(script_tokens) {
                Err(err) => break Err(err)
                Ok(value) => value
              }
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
}

///|
fn Parser::consume_unicode_script_run(
  self : Parser,
  first : UnicodeScript,
) -> ParseResult[(Bool, Array[Token])] {
  let is_subscript = first.kind is UnicodeSubscript
  let tokens : Array[Token] = [Token::make(first.replacement)]
  self.consume()
  for ;; {
    let next = match self.fetch() {
      Err(err) => break Err(err)
      Ok(value) => value
    }
    match lookup_unicode_script(next.text) {
      Some(script) if (script.kind is UnicodeSubscript) == is_subscript => {
        tokens.push(Token::make(script.replacement))
        self.consume()
        continue
      }
      _ => {
        tokens.rev_in_place()
        break Ok((is_subscript, tokens))
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
) -> ParseResult[ParseNode] {
  let symbol_token = self.fetch()
  match symbol_token {
    Err(err) => Err(err)
    Ok(token) => {
      self.consume()
      match self.consume_spaces() {
        Err(err) => Err(err)
        Ok(_) =>
          match self.parse_group(name) {
            Err(err) => Err(err)
            Ok(Some(EmitAtom(group))) => Ok(group)
            Ok(Some(SkipAtom)) =>
              Err(ExpectedGroupAfter(symbol=token.text, loc=token.loc))
            Ok(None) =>
              Err(ExpectedGroupAfter(symbol=token.text, loc=token.loc))
          }
      }
    }
  }
}

///|
fn Parser::parse_group(
  self : Parser,
  name : String,
) -> ParseResult[AtomResult?] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(first_token) => {
      let text = first_token.text
      if text == "{" || text == "\\begingroup" {
        self.consume()
        let group_end = if text == "{" { "}" } else { "\\endgroup" }
        self.gullet.begin_group()
        let expression = self.parse_expression(Some(group_end))
        match expression {
          Err(err) => Err(err)
          Ok(body) => {
            let last_token = self.fetch()
            match last_token {
              Err(err) => Err(err)
              Ok(last) =>
                match self.expect(group_end) {
                  Err(err) => Err(err)
                  Ok(_) =>
                    match self.gullet.end_group() {
                      Err(err) => Err(err)
                      Ok(_) => {
                        let loc = match (first_token.loc, last.loc) {
                          (Some(start_loc), Some(end_loc)) =>
                            Some(SourceLocation::range(start_loc, end_loc))
                          _ => None
                        }
                        Ok(
                          Some(
                            EmitAtom(
                              OrdGroup(
                                mode=self.mode,
                                loc~,
                                body~,
                                semisimple=text == "\\begingroup",
                              ),
                            ),
                          ),
                        )
                      }
                    }
                }
            }
          }
        }
      } else {
        match self.parse_function(Some(name)) {
          Err(err) => Err(err)
          Ok(Some(result)) => Ok(Some(result))
          Ok(None) =>
            match self.parse_symbol() {
              Err(err) => Err(err)
              Ok(Some(node)) => Ok(Some(EmitAtom(node)))
              Ok(None) =>
                if text.length() > 0 && text[0] == '\\' {
                  if self.settings.throw_on_error {
                    Err(
                      UndefinedControlSequence(name=text, loc=first_token.loc),
                    )
                  } else {
                    self.consume()
                    Ok(
                      Some(
                        EmitAtom(
                          format_unsupported_command(
                            self.mode,
                            self.settings,
                            text,
                          ),
                        ),
                      ),
                    )
                  }
                } else {
                  Ok(None)
                }
            }
        }
      }
    }
  }
}

///|
fn Parser::parse_function(
  self : Parser,
  name : String?,
) -> ParseResult[AtomResult?] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(token) =>
      match lookup_function(token.text) {
        None => Ok(None)
        Some(func_data) => {
          self.consume()
          if name is Some(context_name) &&
            context_name != "atom" &&
            !func_data.allowed_in_argument {
            Err(
              FunctionNotAllowed(
                func_name=token.text,
                context=context_name,
                loc=token.loc,
              ),
            )
          } else if self.mode == Text && !func_data.allowed_in_text {
            Err(
              FunctionNotAllowed(
                func_name=token.text,
                context="text mode",
                loc=token.loc,
              ),
            )
          } else if self.mode == Math && !func_data.allowed_in_math {
            Err(
              FunctionNotAllowed(
                func_name=token.text,
                context="math mode",
                loc=token.loc,
              ),
            )
          } else {
            match self.parse_arguments(token.text, func_data) {
              Err(err) => Err(err)
              Ok((args, opt_args)) =>
                match self.call_function(token.text, args, opt_args) {
                  Err(err) => Err(err)
                  Ok(Some(node)) => Ok(Some(EmitAtom(node)))
                  Ok(None) => Ok(Some(SkipAtom))
                }
            }
          }
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
) -> ParseResult[ParseNode?] {
  match lookup_function(func_name) {
    None => Err(MissingFunctionHandler(func_name~, loc=None))
    Some(spec) => (spec.handler)(self, args, opt_args)
  }
}

///|
fn Parser::parse_arguments(
  self : Parser,
  func : String,
  func_data : FunctionSpec,
) -> ParseResult[(Array[ParseNode], Array[ParseNode?])] {
  let args : Array[ParseNode] = []
  let opt_args : Array[ParseNode?] = []
  let total_args = func_data.num_args + func_data.num_optional_args
  for i in 0..<total_args {
    let optional = i < func_data.num_optional_args
    let arg_type = match func_data.arg_types.get(i) {
      Some(kind) => kind
      None => OriginalArg
    }
    match self.parse_group_of_type(arg_type, optional) {
      Err(err) => break Err(err)
      Ok(None) =>
        if optional {
          opt_args.push(None)
          continue
        } else {
          break Err(
            InvalidArgument(message="Missing argument for " + func, loc=None),
          )
        }
      Ok(Some(arg)) => {
        if optional {
          opt_args.push(Some(arg))
        } else {
          args.push(arg)
        }
        continue
      }
    }
  } nobreak {
    Ok((args, opt_args))
  }
}

///|
fn Parser::parse_group_of_type(
  self : Parser,
  arg_type : ArgType,
  optional : Bool,
) -> ParseResult[ParseNode?] {
  match arg_type {
    OriginalArg => self.parse_argument_group(optional)
  }
}

///|
fn Parser::parse_argument_group(
  self : Parser,
  optional : Bool,
) -> ParseResult[ParseNode?] {
  match self.gullet.scan_argument(optional) {
    Err(err) => Err(err)
    Ok(None) => Ok(None)
    Ok(Some(arg_token)) => {
      self.gullet.begin_group()
      let parsed = self.parse_expression(Some("EOF"))
      let result = match parsed {
        Err(err) => Err(err)
        Ok(body) =>
          match self.expect("EOF") {
            Err(err) => Err(err)
            Ok(_) =>
              Ok(
                Some(
                  OrdGroup(
                    mode=self.mode,
                    loc=arg_token.loc,
                    body~,
                    semisimple=false,
                  ),
                ),
              )
          }
      }
      match self.gullet.end_group() {
        Err(err) => Err(err)
        Ok(_) => result
      }
    }
  }
}

///|
fn Parser::parse_symbol(self : Parser) -> ParseResult[ParseNode?] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(token) => {
      let original_text = token.text
      if original_text == "EOF" ||
        original_text == "^" ||
        original_text == "_" ||
        original_text == "{" ||
        original_text == "}" ||
        original_text == "&" {
        Ok(None)
      } else if is_verb_token(original_text) {
        self.consume()
        match parse_verb_token(original_text) {
          Err(err) => Err(err)
          Ok(node) => Ok(Some(node))
        }
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
          None => Ok(None)
          Some(base) => {
            self.consume()
            match mark_start {
              None => Ok(Some(base))
              Some(start) =>
                match
                  apply_unicode_accents(
                    self.mode,
                    token.loc,
                    base,
                    normalized.unsafe_substring(start~, end=normalized.length()),
                  ) {
                  Err(err) => Err(err)
                  Ok(node) => Ok(Some(node))
                }
            }
          }
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
fn parse_verb_token(text : String) -> ParseResult[ParseNode] {
  let raw_argument = text.unsafe_substring(start=5, end=text.length())
  let star = raw_argument.length() > 0 && raw_argument[0] == '*'
  let argument = if star {
    raw_argument.unsafe_substring(start=1, end=raw_argument.length())
  } else {
    raw_argument
  }
  if argument.length() < 2 || argument[0] != argument[argument.length() - 1] {
    Err(
      InternalInvariant(
        message="\\verb assertion failed -- please report what input caused this bug",
      ),
    )
  } else {
    Ok(
      Verb(
        mode=Text,
        loc=None,
        body=argument.unsafe_substring(start=1, end=argument.length() - 1),
        star~,
      ),
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
) -> ParseResult[ParseNode] {
  let mut result = base
  for accent in accents {
    let accent_text = String::from_array([accent])
    let label = match unicode_accent_command(mode, accent_text) {
      Some(command) => command
      None =>
        return Err(
          InvalidArgument(message="Unknown accent ' \{accent_text}'", loc~),
        )
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
  Ok(result)
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
