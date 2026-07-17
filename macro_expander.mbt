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
type MacroHandler = (MacroExpander) -> MacroReplacement raise ParseFailure

///|
fn default_command_status(name : String) -> ExternalCommandStatus {
  match lookup_function(name) {
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
}

///|
priv struct MacroExpander {
  settings : Settings
  mut expansion_count : Int
  mut lexer : Lexer
  macros : Namespace[MacroDefinition]
  dynamic_macros : Namespace[MacroHandler]
  stack : Array[Token]
  mut mode : Mode
  report_nonstrict : LexerReporter
  command_status : CommandStatusResolver
  math_symbol_group : MathSymbolGroupResolver
  macro_reporter : MacroReporter
}

///|
fn MacroExpander::make(
  input : String,
  settings : Settings,
  mode? : Mode = Math,
  builtins? : Map[String, MacroDefinition] = builtin_static_macros(),
  dynamic_macros? : Map[String, MacroHandler] = builtin_dynamic_macros(),
  report_nonstrict? : LexerReporter = (_code, _message) => (),
  command_status? : CommandStatusResolver = default_command_status,
  math_symbol_group? : MathSymbolGroupResolver = default_math_symbol_group,
  macro_reporter? : MacroReporter = default_macro_reporter,
) -> MacroExpander {
  {
    settings,
    expansion_count: 0,
    lexer: Lexer::make(input, report_nonstrict~),
    macros: Namespace::make(builtins, settings.macro_definitions()),
    dynamic_macros: Namespace::make(dynamic_macros, Map([])),
    stack: [],
    mode,
    report_nonstrict,
    command_status,
    math_symbol_group,
    macro_reporter,
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
  self.dynamic_macros.begin_group()
}

///|
fn MacroExpander::end_group(self : MacroExpander) -> Unit raise ParseFailure {
  self.dynamic_macros.end_group()
  self.macros.end_group()
}

///|
fn MacroExpander::end_groups(self : MacroExpander) -> Unit {
  self.macros.end_groups()
  self.dynamic_macros.end_groups()
}

///|
fn MacroExpander::future(self : MacroExpander) -> Token raise ParseFailure {
  if self.stack.is_empty() {
    let token = self.lexer.lex()
    self.stack.push(token)
    token
  } else {
    match self.stack.last() {
      Some(token) => token
      None => raise InternalInvariant(message="Empty token stack")
    }
  }
}

///|
fn MacroExpander::pop_token(self : MacroExpander) -> Token raise ParseFailure {
  let _ = self.future()
  match self.stack.pop() {
    Some(token) => token
    None => raise InternalInvariant(message="Empty token stack")
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
fn MacroExpander::consume_spaces(
  self : MacroExpander,
) -> Unit raise ParseFailure {
  for ;; {
    let token = self.future()
    guard token.text == " " else { break }
    match self.stack.pop() {
      Some(_) => continue
      None => raise InternalInvariant(message="Empty token stack")
    }
  }
}

///|
fn MacroExpander::scan_argument(
  self : MacroExpander,
  optional : Bool,
) -> Token? raise ParseFailure {
  if optional {
    self.consume_spaces()
    if self.future().text != "[" {
      None
    } else {
      let start = self.pop_token()
      let arg = self.consume_arg(Some(["]"]))
      Some(self.push_argument_job(start, arg))
    }
  } else {
    let arg = self.consume_arg(None)
    Some(self.push_argument_job(arg.start, arg))
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
) -> MacroArgument raise ParseFailure {
  let is_delimited = match delimiters {
    Some(values) => !values.is_empty()
    None => false
  }
  if !is_delimited {
    self.consume_spaces()
  }
  let start = self.future()
  let tokens : Array[Token] = []
  let mut depth = 0
  let mut delimiter_match = 0
  for ;; {
    let token = self.pop_token()
    tokens.push(token)
    if token.text == "{" {
      depth = depth + 1
    } else if token.text == "}" {
      depth = depth - 1
      if depth == -1 {
        raise InvalidArgument(message="Extra }", loc=token.loc)
      }
    } else if token.text == "EOF" {
      raise InvalidArgument(
        message="Unexpected end of input in a macro argument, expected '" +
          expected_argument_delimiter(delimiters, delimiter_match) +
          "'",
        loc=token.loc,
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
          break { start, end: token, tokens: normalized }
        }
      } else {
        delimiter_match = 0
      }
    }
    if depth == 0 && !is_delimited {
      let normalized = normalize_consumed_argument(start, tokens)
      break { start, end: token, tokens: normalized }
    }
  }
}

///|
fn MacroExpander::consume_args(
  self : MacroExpander,
  num_args : Int,
  delimiters : Array[Array[String]]?,
) -> Array[Array[Token]] raise ParseFailure {
  if delimiters is Some(values) && values.length() != num_args + 1 {
    raise InvalidArgument(
      message="The length of delimiters doesn't match the number of args!",
      loc=None,
    )
  }
  if delimiters is Some(values) {
    match values.get(0) {
      Some(prefix) =>
        for expected in prefix {
          let token = self.pop_token()
          if token.text != expected {
            raise InvalidArgument(
              message="Use of the macro doesn't match its definition",
              loc=token.loc,
            )
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
    args.push(self.consume_arg(argument_delimiters).tokens)
  }
  args
}

///|
fn MacroExpander::count_expansion(
  self : MacroExpander,
  amount : Int,
) -> Unit raise ParseFailure {
  self.expansion_count = self.expansion_count + amount
  if self.expansion_count > self.settings.max_expand {
    raise TooManyExpansions(limit=self.settings.max_expand)
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
) -> Array[Token] raise ParseFailure {
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
        raise InvalidArgument(
          message="Incomplete placeholder at end of macro body",
          loc=token.loc,
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
                  raise InvalidArgument(
                    message="Not a valid argument number",
                    loc=next.loc,
                  )
              }
            None =>
              raise InvalidArgument(
                message="Not a valid argument number",
                loc=next.loc,
              )
          }
        }
    }
  } nobreak {
    output.rev_in_place()
    output
  }
}

///|
fn MacroExpander::expand_once(
  self : MacroExpander,
  expandable_only? : Bool = false,
) -> ExpansionStep raise ParseFailure {
  let top_token = self.pop_token()
  let expansion = if top_token.noexpand {
    None
  } else {
    self.get_expansion(top_token.text)
  }
  match expansion {
    None =>
      if expandable_only &&
        top_token.text.length() > 0 &&
        top_token.text[0] == '\\' &&
        !self.is_defined(top_token.text) {
        raise UndefinedControlSequence(name=top_token.text, loc=None)
      } else {
        self.push_token(top_token)
        NotExpanded
      }
    Some(value) =>
      if expandable_only && value.unexpandable {
        self.push_token(top_token)
        NotExpanded
      } else {
        self.count_expansion(1)
        let args = self.consume_args(value.num_args, value.delimiters)
        let tokens = if value.num_args == 0 {
          value.tokens
        } else {
          substitute_macro_arguments(value.tokens, args)
        }
        self.push_tokens(tokens)
        Expanded(tokens.length())
      }
  }
}

///|
#warnings("-unused_value")
fn MacroExpander::expand_after_future(
  self : MacroExpander,
) -> Token raise ParseFailure {
  let _ = self.expand_once()
  self.future()
}

///|
fn MacroExpander::expand_next_token(
  self : MacroExpander,
) -> Token raise ParseFailure {
  for ;; {
    match self.expand_once() {
      Expanded(_) => continue
      NotExpanded =>
        match self.stack.pop() {
          Some(token) => {
            if token.treat_as_relax {
              token.text = "\\relax"
            }
            break token
          }
          None => raise InternalInvariant(message="Empty token stack")
        }
    }
  }
}

///|
fn MacroExpander::expand_tokens(
  self : MacroExpander,
  tokens : Array[Token],
) -> Array[Token] raise ParseFailure {
  let output : Array[Token] = []
  let old_stack_length = self.stack.length()
  self.push_tokens(tokens)
  while self.stack.length() > old_stack_length {
    match self.expand_once(expandable_only=true) {
      Expanded(_) => ()
      NotExpanded =>
        match self.stack.pop() {
          Some(token) => {
            if token.treat_as_relax {
              token.noexpand = false
              token.treat_as_relax = false
            }
            output.push(token)
          }
          None => raise InternalInvariant(message="Empty token stack")
        }
    }
  }
  self.count_expansion(output.length())
  output
}

///|
fn MacroExpander::expand_macro(
  self : MacroExpander,
  name : String,
) -> Array[Token]? raise ParseFailure {
  if !self.macros.has(name) && !self.dynamic_macros.has(name) {
    None
  } else {
    Some(self.expand_tokens([Token::make(name)]))
  }
}

///|
#warnings("-unused_value")
fn MacroExpander::expand_macro_as_text(
  self : MacroExpander,
  name : String,
) -> String? raise ParseFailure {
  match self.expand_macro(name) {
    None => None
    Some(tokens) => {
      let mut output = ""
      for token in tokens {
        output = output + token.text
      }
      Some(output)
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
) -> MacroExpansion raise ParseFailure {
  let lexer = Lexer::make(expansion, report_nonstrict=self.report_nonstrict)
  let tokens : Array[Token] = []
  for ;; {
    let token = lexer.lex()
    if token.text == "EOF" {
      tokens.rev_in_place()
      break MacroExpansion::make(
        tokens,
        num_args=inferred_argument_count(expansion),
      )
    } else {
      tokens.push(token)
      continue
    }
  }
}

///|
fn MacroExpander::resolve_replacement(
  self : MacroExpander,
  replacement : MacroReplacement,
) -> MacroExpansion raise ParseFailure {
  match replacement {
    ReplacementText(text) => self.lex_macro_body(text)
    ReplacementExpansion(expansion) => expansion
  }
}

///|
fn MacroExpander::get_expansion(
  self : MacroExpander,
  name : String,
) -> MacroExpansion? raise ParseFailure {
  if name.length() == 1 && self.lexer.catcode(name) is Some(code) && code != 13 {
    return None
  }
  match self.dynamic_macros.get_current(name) {
    Some(handler) => Some(self.resolve_replacement(handler(self)))
    None => self.get_static_or_builtin_dynamic_expansion(name)
  }
}

///|
fn MacroExpander::get_static_or_builtin_dynamic_expansion(
  self : MacroExpander,
  name : String,
) -> MacroExpansion? raise ParseFailure {
  match self.macros.get(name) {
    Some(definition) =>
      match definition {
        Text(expansion) => Some(self.lex_macro_body(expansion))
        Expansion(expansion) => Some(expansion)
      }
    None =>
      match self.dynamic_macros.get_builtin(name) {
        None => None
        Some(handler) => Some(self.resolve_replacement(handler(self)))
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
  self.dynamic_macros.has(name) ||
  external_defined ||
  is_implicit_command(name)
}

///|
#warnings("-unused_value")
fn MacroExpander::is_expandable(self : MacroExpander, name : String) -> Bool {
  match self.dynamic_macros.get_current(name) {
    Some(_) => true
    None => self.is_static_or_builtin_dynamic_expandable(name)
  }
}

///|
fn MacroExpander::is_static_or_builtin_dynamic_expandable(
  self : MacroExpander,
  name : String,
) -> Bool {
  match self.macros.get(name) {
    Some(definition) =>
      match definition {
        Text(_) => true
        Expansion(value) => !value.unexpandable
      }
    None =>
      if self.dynamic_macros.get_builtin(name) is Some(_) {
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
