///|
#warnings("-unused_constructor")
priv enum MacroReplacement {
  ReplacementText(String)
  ReplacementExpansion(MacroExpansion)
}

///|
#warnings("-unused_field")
priv enum ExpansionStep {
  NotExpanded
  Expanded(Int)
}

///|
#warnings("-unused_constructor")
priv enum ExternalCommandStatus {
  ExternalUndefined
  ExternalExpandable
  ExternalUnexpandable
}

///|
type CommandStatusResolver = (String) -> ExternalCommandStatus

///|
type MacroHandler = (MacroExpander) -> ParseResult[MacroReplacement]

///|
fn default_command_status(name : String) -> ExternalCommandStatus {
  if is_registered_function(name) {
    ExternalExpandable
  } else {
    ExternalUndefined
  }
}

///|
priv struct MacroExpander {
  settings : Settings
  mut expansion_count : Int
  mut lexer : Lexer
  macros : Namespace[MacroDefinition]
  dynamic_macros : Map[String, MacroHandler]
  stack : Array[Token]
  mut mode : Mode
  report_nonstrict : LexerReporter
  command_status : CommandStatusResolver
}

///|
fn MacroExpander::make(
  input : String,
  settings : Settings,
  mode? : Mode = Math,
  builtins? : Map[String, MacroDefinition] = Map([]),
  dynamic_macros? : Map[String, MacroHandler] = Map([]),
  report_nonstrict? : LexerReporter = discard_lexer_diagnostic,
  command_status? : CommandStatusResolver = default_command_status,
) -> MacroExpander {
  {
    settings,
    expansion_count: 0,
    lexer: Lexer::make(input, report_nonstrict~),
    macros: Namespace::make(builtins, settings.macros),
    dynamic_macros,
    stack: [],
    mode,
    report_nonstrict,
    command_status,
  }
}

///|
#warnings("-unused_value")
fn MacroExpander::feed(self : MacroExpander, input : String) -> Unit {
  self.lexer = Lexer::make(input, report_nonstrict=self.report_nonstrict)
}

///|
#warnings("-unused_value")
fn MacroExpander::switch_mode(self : MacroExpander, mode : Mode) -> Unit {
  if self.mode != mode {
    self.mode = mode
  }
}

///|
fn MacroExpander::begin_group(self : MacroExpander) -> Unit {
  self.macros.begin_group()
}

///|
fn MacroExpander::end_group(self : MacroExpander) -> ParseResult[Unit] {
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
    Err(err) => Err(err)
    Ok(_) =>
      match self.stack.pop() {
        Some(token) => Ok(token)
        None => Err(InternalInvariant(message="Empty token stack"))
      }
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
      Err(err) => break Err(err)
      Ok(token) =>
        if token.text == " " {
          match self.stack.pop() {
            Some(_) => continue
            None => break Err(InternalInvariant(message="Empty token stack"))
          }
        } else {
          break Ok(())
        }
    }
  }
}

///|
fn MacroExpander::scan_argument(
  self : MacroExpander,
  optional : Bool,
) -> ParseResult[Token?] {
  if optional {
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
                Ok(start) =>
                  match self.consume_arg(Some(["]"])) {
                    Err(err) => Err(err)
                    Ok(arg) => Ok(Some(self.push_argument_job(start, arg)))
                  }
              }
            }
        }
    }
  } else {
    match self.consume_arg(None) {
      Err(err) => Err(err)
      Ok(arg) => Ok(Some(self.push_argument_job(arg.start, arg)))
    }
  }
}

///|
fn MacroExpander::push_argument_job(
  self : MacroExpander,
  start : Token,
  arg : MacroArgument,
) -> Token {
  let eof = match arg.end.loc {
    Some(loc) => Token::make("EOF", loc~)
    None => Token::make("EOF")
  }
  self.push_token(eof)
  self.push_tokens(arg.tokens)
  start.range(arg.end, "")
}

///|
fn delimiter_is_active(
  delimiters : Array[String],
  match_index : Int,
  depth : Int,
  token : Token,
) -> Bool {
  match delimiters.get(match_index) {
    Some(delimiter) =>
      (depth == 0 || (depth == 1 && delimiter == "{")) &&
      token.text == delimiter
    None => false
  }
}

///|
fn expected_argument_delimiter(
  delimiters : Array[String]?,
  match_index : Int,
) -> String {
  match delimiters {
    Some(values) =>
      match values.get(match_index) {
        Some(value) => value
        None => "}"
      }
    None => "}"
  }
}

///|
fn normalize_consumed_argument(
  start : Token,
  tokens : Array[Token],
) -> Array[Token] {
  if start.text == "{" && tokens.last() is Some(last) && last.text == "}" {
    let without_braces = tokens[1:tokens.length() - 1].to_owned()
    without_braces.rev_in_place()
    without_braces
  } else {
    tokens.rev_in_place()
    tokens
  }
}

///|
fn MacroExpander::consume_arg(
  self : MacroExpander,
  delimiters : Array[String]?,
) -> ParseResult[MacroArgument] {
  let is_delimited = match delimiters {
    Some(values) => !values.is_empty()
    None => false
  }
  if !is_delimited {
    match self.consume_spaces() {
      Err(err) => return Err(err)
      Ok(_) => ()
    }
  }
  let start = match self.future() {
    Err(err) => return Err(err)
    Ok(token) => token
  }
  let tokens : Array[Token] = []
  let mut depth = 0
  let mut delimiter_match = 0
  for ;; {
    let token = match self.pop_token() {
      Err(err) => break Err(err)
      Ok(value) => value
    }
    tokens.push(token)
    if token.text == "{" {
      depth = depth + 1
    } else if token.text == "}" {
      depth = depth - 1
      if depth == -1 {
        break Err(InvalidArgument(message="Extra }", loc=token.loc))
      }
    } else if token.text == "EOF" {
      break Err(
        InvalidArgument(
          message="Unexpected end of input in a macro argument, expected '" +
            expected_argument_delimiter(delimiters, delimiter_match) +
            "'",
          loc=token.loc,
        ),
      )
    }
    if delimiters is Some(values) && is_delimited {
      if delimiter_is_active(values, delimiter_match, depth, token) {
        delimiter_match = delimiter_match + 1
        if delimiter_match == values.length() {
          for _ in 0..<delimiter_match {
            let _ = tokens.pop()
          }
          let normalized = normalize_consumed_argument(start, tokens)
          break Ok({ start, end: token, tokens: normalized })
        }
      } else {
        delimiter_match = 0
      }
    }
    if depth == 0 && !is_delimited {
      let normalized = normalize_consumed_argument(start, tokens)
      break Ok({ start, end: token, tokens: normalized })
    }
  }
}

///|
fn MacroExpander::consume_args(
  self : MacroExpander,
  num_args : Int,
  delimiters : Array[Array[String]]?,
) -> ParseResult[Array[Array[Token]]] {
  if delimiters is Some(values) && values.length() != num_args + 1 {
    return Err(
      InvalidArgument(
        message="The length of delimiters doesn't match the number of args!",
        loc=None,
      ),
    )
  }
  if delimiters is Some(values) {
    match values.get(0) {
      Some(prefix) =>
        for expected in prefix {
          match self.pop_token() {
            Err(err) => return Err(err)
            Ok(token) =>
              if token.text != expected {
                return Err(
                  InvalidArgument(
                    message="Use of the macro doesn't match its definition",
                    loc=token.loc,
                  ),
                )
              }
          }
        }
      None => ()
    }
  }
  let args : Array[Array[Token]] = []
  for index in 0..<num_args {
    let argument_delimiters = match delimiters {
      Some(values) => values.get(index + 1)
      None => None
    }
    match self.consume_arg(argument_delimiters) {
      Err(err) => return Err(err)
      Ok(argument) => args.push(argument.tokens)
    }
  }
  Ok(args)
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
fn placeholder_number(text : String) -> Int? {
  if text.length() == 1 && text[0] >= '1' && text[0] <= '9' {
    Some(text[0].to_int() - ('0' : UInt16).to_int())
  } else {
    None
  }
}

///|
fn substitute_macro_arguments(
  tokens : Array[Token],
  args : Array[Array[Token]],
) -> ParseResult[Array[Token]] {
  let forward = tokens.rev()
  let output : Array[Token] = []
  for index = 0; index < forward.length(); {
    let token = forward[index]
    if token.text != "#" {
      output.push(token)
      continue index + 1
    }
    match forward.get(index + 1) {
      None =>
        break Err(
          InvalidArgument(
            message="Incomplete placeholder at end of macro body",
            loc=token.loc,
          ),
        )
      Some(next) =>
        if next.text == "#" {
          output.push(next)
          continue index + 2
        } else {
          match placeholder_number(next.text) {
            Some(number) =>
              match args.get(number - 1) {
                Some(argument) => {
                  output.append(argument.rev())
                  continue index + 2
                }
                None =>
                  break Err(
                    InvalidArgument(
                      message="Not a valid argument number",
                      loc=next.loc,
                    ),
                  )
              }
            None =>
              break Err(
                InvalidArgument(
                  message="Not a valid argument number",
                  loc=next.loc,
                ),
              )
          }
        }
    }
  } nobreak {
    output.rev_in_place()
    Ok(output)
  }
}

///|
fn MacroExpander::expand_once(
  self : MacroExpander,
  expandable_only? : Bool = false,
) -> ParseResult[ExpansionStep] {
  let top_token = match self.pop_token() {
    Err(err) => return Err(err)
    Ok(token) => token
  }
  let expansion = if top_token.noexpand {
    Ok(None)
  } else {
    self.get_expansion(top_token.text)
  }
  match expansion {
    Err(err) => Err(err)
    Ok(None) =>
      if expandable_only &&
        top_token.text.length() > 0 &&
        top_token.text[0] == '\\' &&
        !self.is_defined(top_token.text) {
        Err(UndefinedControlSequence(name=top_token.text, loc=None))
      } else {
        self.push_token(top_token)
        Ok(NotExpanded)
      }
    Ok(Some(value)) =>
      if expandable_only && value.unexpandable {
        self.push_token(top_token)
        Ok(NotExpanded)
      } else {
        match self.count_expansion(1) {
          Err(err) => Err(err)
          Ok(_) =>
            match self.consume_args(value.num_args, value.delimiters) {
              Err(err) => Err(err)
              Ok(args) => {
                let tokens = if value.num_args == 0 {
                  value.tokens
                } else {
                  match substitute_macro_arguments(value.tokens, args) {
                    Err(err) => return Err(err)
                    Ok(result) => result
                  }
                }
                self.push_tokens(tokens)
                Ok(Expanded(tokens.length()))
              }
            }
        }
      }
  }
}

///|
#warnings("-unused_value")
fn MacroExpander::expand_after_future(
  self : MacroExpander,
) -> ParseResult[Token] {
  match self.expand_once() {
    Err(err) => Err(err)
    Ok(_) => self.future()
  }
}

///|
fn MacroExpander::expand_next_token(self : MacroExpander) -> ParseResult[Token] {
  for ;; {
    match self.expand_once() {
      Err(err) => break Err(err)
      Ok(Expanded(_)) => continue
      Ok(NotExpanded) =>
        match self.stack.pop() {
          Some(token) => {
            if token.treat_as_relax {
              token.text = "\\relax"
            }
            break Ok(token)
          }
          None => break Err(InternalInvariant(message="Empty token stack"))
        }
    }
  }
}

///|
fn MacroExpander::expand_tokens(
  self : MacroExpander,
  tokens : Array[Token],
) -> ParseResult[Array[Token]] {
  let output : Array[Token] = []
  let old_stack_length = self.stack.length()
  self.push_tokens(tokens)
  while self.stack.length() > old_stack_length {
    match self.expand_once(expandable_only=true) {
      Err(err) => return Err(err)
      Ok(Expanded(_)) => ()
      Ok(NotExpanded) =>
        match self.stack.pop() {
          Some(token) => {
            if token.treat_as_relax {
              token.noexpand = false
              token.treat_as_relax = false
            }
            output.push(token)
          }
          None => return Err(InternalInvariant(message="Empty token stack"))
        }
    }
  }
  match self.count_expansion(output.length()) {
    Err(err) => Err(err)
    Ok(_) => Ok(output)
  }
}

///|
fn MacroExpander::expand_macro(
  self : MacroExpander,
  name : String,
) -> ParseResult[Array[Token]?] {
  if !self.macros.has(name) && !self.dynamic_macros.contains(name) {
    Ok(None)
  } else {
    match self.expand_tokens([Token::make(name)]) {
      Err(err) => Err(err)
      Ok(tokens) => Ok(Some(tokens))
    }
  }
}

///|
#warnings("-unused_value")
fn MacroExpander::expand_macro_as_text(
  self : MacroExpander,
  name : String,
) -> ParseResult[String?] {
  match self.expand_macro(name) {
    Err(err) => Err(err)
    Ok(None) => Ok(None)
    Ok(Some(tokens)) => {
      let mut output = ""
      for token in tokens {
        output = output + token.text
      }
      Ok(Some(output))
    }
  }
}

///|
fn inferred_argument_count(expansion : String) -> Int {
  let seen : FixedArray[Bool] = FixedArray::make(10, false)
  for index = 0; index < expansion.length(); {
    if expansion[index] != '#' || index + 1 >= expansion.length() {
      continue index + 1
    }
    if expansion[index + 1] == '#' {
      continue index + 2
    }
    let digit = expansion[index + 1]
    if digit >= '1' && digit <= '9' {
      seen[digit.to_int() - ('0' : UInt16).to_int()] = true
      continue index + 2
    }
    continue index + 1
  }
  for count = 0; count < 9; count = count + 1 {
    if !seen[count + 1] {
      break count
    }
  } nobreak {
    9
  }
}

///|
fn MacroExpander::lex_macro_body(
  self : MacroExpander,
  expansion : String,
) -> ParseResult[MacroExpansion] {
  let lexer = Lexer::make(expansion, report_nonstrict=self.report_nonstrict)
  let tokens : Array[Token] = []
  for ;; {
    match lexer.lex() {
      Err(err) => break Err(err)
      Ok(token) =>
        if token.text == "EOF" {
          tokens.rev_in_place()
          break Ok(
            MacroExpansion::make(
              tokens,
              num_args=inferred_argument_count(expansion),
            ),
          )
        } else {
          tokens.push(token)
          continue
        }
    }
  }
}

///|
fn MacroExpander::resolve_replacement(
  self : MacroExpander,
  replacement : MacroReplacement,
) -> ParseResult[MacroExpansion] {
  match replacement {
    ReplacementText(text) => self.lex_macro_body(text)
    ReplacementExpansion(expansion) => Ok(expansion)
  }
}

///|
fn MacroExpander::get_expansion(
  self : MacroExpander,
  name : String,
) -> ParseResult[MacroExpansion?] {
  if name.length() == 1 && self.lexer.catcode(name) is Some(code) && code != 13 {
    return Ok(None)
  }
  match self.macros.get(name) {
    Some(definition) =>
      match definition {
        Text(expansion) =>
          match self.lex_macro_body(expansion) {
            Err(err) => Err(err)
            Ok(value) => Ok(Some(value))
          }
        Expansion(expansion) => Ok(Some(expansion))
      }
    None =>
      match self.dynamic_macros.get(name) {
        None => Ok(None)
        Some(handler) =>
          match handler(self) {
            Err(err) => Err(err)
            Ok(replacement) =>
              match self.resolve_replacement(replacement) {
                Err(err) => Err(err)
                Ok(value) => Ok(Some(value))
              }
          }
      }
  }
}

///|
fn MacroExpander::is_defined(self : MacroExpander, name : String) -> Bool {
  let external_defined = match (self.command_status)(name) {
    ExternalUndefined => false
    ExternalExpandable | ExternalUnexpandable => true
  }
  self.macros.has(name) ||
  self.dynamic_macros.contains(name) ||
  external_defined ||
  is_implicit_command(name)
}

///|
#warnings("-unused_value")
fn MacroExpander::is_expandable(self : MacroExpander, name : String) -> Bool {
  match self.macros.get(name) {
    Some(definition) =>
      match definition {
        Text(_) => true
        Expansion(value) => !value.unexpandable
      }
    None =>
      if self.dynamic_macros.contains(name) {
        true
      } else {
        match (self.command_status)(name) {
          ExternalExpandable => true
          ExternalUndefined | ExternalUnexpandable => false
        }
      }
  }
}

///|
fn is_implicit_command(name : String) -> Bool {
  name == "^" || name == "_" || name == "\\limits" || name == "\\nolimits"
}
