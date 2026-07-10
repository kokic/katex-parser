///|
priv struct MacroExpander {
  settings : Settings
  mut expansion_count : Int
  lexer : Lexer
  macros : Namespace[MacroDefinition]
  stack : Array[Token]
}

///|
fn MacroExpander::make(input : String, settings : Settings) -> MacroExpander {
  {
    settings,
    expansion_count: 0,
    lexer: Lexer::make(input, settings),
    macros: Namespace::make({}, settings.macros),
    stack: [],
  }
}

///|
fn MacroExpander::begin_group(self : MacroExpander) -> Unit {
  self.macros.begin_group()
}

///|
fn MacroExpander::end_group(self : MacroExpander) -> Unit {
  self.macros.end_group()
}

///|
fn MacroExpander::end_groups(self : MacroExpander) -> Unit {
  self.macros.end_groups()
}

///|
fn MacroExpander::future(self : MacroExpander) -> ParseResult[Token] {
  if self.stack.is_empty() {
    match self.lexer.lex() {
      Ok(token) => {
        self.stack.push(token)
        Ok(token)
      }
      Err(err) => Err(err)
    }
  } else {
    match self.stack.last() {
      Some(token) => Ok(token)
      None => Err(InternalInvariant(message="Empty token stack"))
    }
  }
}

///|
fn MacroExpander::pop_token(self : MacroExpander) -> ParseResult[Token] {
  match self.future() {
    Ok(_) =>
      match self.stack.pop() {
        Some(token) => Ok(token)
        None => Err(InternalInvariant(message="Empty token stack"))
      }
    Err(err) => Err(err)
  }
}

///|
fn MacroExpander::push_token(self : MacroExpander, token : Token) -> Unit {
  self.stack.push(token)
}

///|
fn MacroExpander::push_tokens(
  self : MacroExpander,
  tokens : Array[Token],
) -> Unit {
  self.stack.append(tokens)
}

///|
fn MacroExpander::consume_spaces(self : MacroExpander) -> ParseResult[Unit] {
  for ;; {
    match self.future() {
      Ok(token) =>
        if token.text == " " {
          ignore(self.stack.pop())
          continue
        } else {
          break Ok(())
        }
      Err(err) => break Err(err)
    }
  }
}

///|
fn MacroExpander::scan_argument(
  self : MacroExpander,
  optional : Bool,
) -> ParseResult[Token?] {
  if optional {
    self.scan_optional_argument()
  } else {
    self.scan_required_argument()
  }
}

///|
fn MacroExpander::scan_optional_argument(
  self : MacroExpander,
) -> ParseResult[Token?] {
  match self.consume_spaces() {
    Err(err) => Err(err)
    Ok(_) =>
      match self.future() {
        Err(err) => Err(err)
        Ok(token) =>
          if token.text != "[" {
            Ok(None)
          } else {
            match self.pop_token() {
              Err(err) => Err(err)
              Ok(start_token) =>
                match self.consume_argument(Some("]")) {
                  Err(err) => Err(err)
                  Ok(arg) =>
                    Ok(Some(self.prepare_scanned_argument(start_token, arg)))
                }
            }
          }
      }
  }
}

///|
fn MacroExpander::scan_required_argument(
  self : MacroExpander,
) -> ParseResult[Token?] {
  match self.consume_argument(None) {
    Err(err) => Err(err)
    Ok(arg) => Ok(Some(self.prepare_scanned_argument(arg.start, arg)))
  }
}

///|
fn MacroExpander::prepare_scanned_argument(
  self : MacroExpander,
  start : Token,
  arg : MacroArgument,
) -> Token {
  let eof_token = match arg.end.loc {
    Some(loc) => Token::make("EOF", loc~)
    None => Token::make("EOF")
  }
  self.push_token(eof_token)
  self.push_tokens(arg.tokens)
  start.range(arg.end, "")
}

///|
fn MacroExpander::consume_argument(
  self : MacroExpander,
  delimiter : String?,
) -> ParseResult[MacroArgument] {
  if delimiter is None {
    match self.consume_spaces() {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  let start_result = self.future()
  match start_result {
    Err(err) => Err(err)
    Ok(start) => {
      let tokens : Array[Token] = []
      let mut depth = 0
      for ;; {
        match self.pop_token() {
          Err(err) => break Err(err)
          Ok(token) => {
            if token.text == "EOF" {
              break Err(
                InvalidArgument(
                  message="Unexpected end of input in argument",
                  token=Some(token),
                ),
              )
            }
            if delimiter is Some(delim) && depth == 0 && token.text == delim {
              tokens.rev_in_place()
              break Ok({ start, end: token, tokens })
            }
            tokens.push(token)
            if token.text == "{" {
              depth = depth + 1
            } else if token.text == "}" {
              depth = depth - 1
              if depth < 0 {
                break Err(InvalidArgument(message="Extra }", token=Some(token)))
              } else if delimiter is None && depth == 0 {
                if start.text == "{" {
                  ignore(tokens.pop())
                  ignore(tokens.remove(0))
                }
                tokens.rev_in_place()
                break Ok({ start, end: token, tokens })
              }
            }
            if delimiter is None && depth == 0 && start.text != "{" {
              tokens.rev_in_place()
              break Ok({ start, end: token, tokens })
            }
          }
        }
      }
    }
  }
}

///|
fn MacroExpander::count_expansion(
  self : MacroExpander,
  amount : Int,
) -> ParseResult[Unit] {
  self.expansion_count = self.expansion_count + amount
  if self.expansion_count > self.settings.max_expand {
    Err(TooManyExpansions(limit=self.settings.max_expand))
  } else {
    Ok(())
  }
}

///|
fn MacroExpander::expand_once(
  self : MacroExpander,
  expandable_only? : Bool = false,
) -> ParseResult[Bool] {
  match self.pop_token() {
    Err(err) => Err(err)
    Ok(top_token) => {
      let name = top_token.text
      let expansion = if top_token.noexpand {
        Ok(None)
      } else {
        self.get_expansion(name)
      }
      match expansion {
        Err(err) => Err(err)
        Ok(None) =>
          if expandable_only &&
            name.length() > 0 &&
            name[0] == '\\' &&
            !self.is_defined(name) {
            Err(UndefinedControlSequence(name~, token=top_token))
          } else {
            self.push_token(top_token)
            Ok(false)
          }
        Ok(Some(tokens)) =>
          match self.count_expansion(1) {
            Err(err) => Err(err)
            Ok(_) => {
              self.push_tokens(tokens)
              Ok(true)
            }
          }
      }
    }
  }
}

///|
fn MacroExpander::expand_next_token(self : MacroExpander) -> ParseResult[Token] {
  for ;; {
    match self.expand_once() {
      Err(err) => break Err(err)
      Ok(false) =>
        match self.stack.pop() {
          Some(token) => {
            if token.treat_as_relax {
              token.text = "\\relax"
            }
            break Ok(token)
          }
          None => break Err(InternalInvariant(message="Empty token stack"))
        }
      Ok(true) => continue
    }
  }
}

///|
fn MacroExpander::get_expansion(
  self : MacroExpander,
  name : String,
) -> ParseResult[Array[Token]?] {
  match self.macros.get(name) {
    None => Ok(None)
    Some(definition) =>
      match definition {
        Text(expansion) =>
          match tokens_from_macro_text(expansion, self.settings) {
            Ok(tokens) => Ok(Some(tokens))
            Err(err) => Err(err)
          }
        Expansion(tokens~, unexpandable~, ..) =>
          if unexpandable {
            Ok(None)
          } else {
            Ok(Some(tokens.copy()))
          }
      }
  }
}

///|
fn tokens_from_macro_text(
  expansion : String,
  settings : Settings,
) -> ParseResult[Array[Token]] {
  let lexer = Lexer::make(expansion, settings)
  let tokens : Array[Token] = []
  for ;; {
    match lexer.lex() {
      Ok(token) =>
        if token.text == "EOF" {
          break Ok(tokens.rev())
        } else {
          tokens.push(token)
          continue
        }
      Err(err) => break Err(err)
    }
  }
}

///|
fn MacroExpander::is_defined(self : MacroExpander, name : String) -> Bool {
  self.macros.has(name) ||
  is_registered_function(name) ||
  is_implicit_command(name)
}

///|
fn is_implicit_command(name : String) -> Bool {
  name == "^" || name == "_" || name == "\\limits" || name == "\\nolimits"
}
