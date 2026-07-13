///|
fn digit_value(text : String) -> Int? {
  if text.length() != 1 {
    None
  } else {
    let code = text[0]
    if code >= '0' && code <= '9' {
      Some(code.to_int() - ('0' : UInt16).to_int())
    } else if code >= 'a' && code <= 'f' {
      Some(code.to_int() - ('a' : UInt16).to_int() + 10)
    } else if code >= 'A' && code <= 'F' {
      Some(code.to_int() - ('A' : UInt16).to_int() + 10)
    } else {
      None
    }
  }
}

///|
fn char_code_from_token(token : Token) -> ParseResult[Int] {
  if token.text == "EOF" {
    Err(InvalidArgument(message="\\char` missing argument", loc=token.loc))
  } else if token.text.length() > 1 && token.text[0] == '\\' {
    Ok(token.text[1].to_int())
  } else {
    Ok(token.text[0].to_int())
  }
}

///|
fn parse_char_number(
  context : MacroExpander,
  first : Token,
  base : Int,
) -> ParseResult[Int] {
  let first_digit = match digit_value(first.text) {
    Some(value) if value < base => value
    _ =>
      return Err(
        InvalidArgument(
          message="Invalid base-\{base} digit \{first.text}",
          loc=first.loc,
        ),
      )
  }
  for number = first_digit {
    let token = match context.future() {
      Err(err) => break Err(err)
      Ok(value) => value
    }
    match digit_value(token.text) {
      Some(digit) if digit < base =>
        match context.pop_token() {
          Err(err) => break Err(err)
          Ok(_) => {
            let next = if number > (2147483647 - digit) / base {
              2147483647
            } else {
              number * base + digit
            }
            continue next
          }
        }
      _ => break Ok(number)
    }
  }
}

///|
fn char_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  let first = match context.pop_token() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let number = if first.text == "`" {
    let token = match context.pop_token() {
      Err(err) => return Err(err)
      Ok(value) => value
    }
    match char_code_from_token(token) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  } else {
    let (base, digit) = if first.text == "'" {
      let token = match context.pop_token() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      (8, token)
    } else if first.text == "\"" {
      let token = match context.pop_token() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      (16, token)
    } else {
      (10, first)
    }
    match parse_char_number(context, digit, base) {
      Err(err) => return Err(err)
      Ok(value) => value
    }
  }
  Ok(ReplacementText("\\@char{\{number}}"))
}

///|
fn parse_argument_count(text : String) -> Int? {
  let mut number = 0
  let mut saw_digit = false
  let mut trailing_space = false
  for code in text {
    if code >= '0' && code <= '9' && !trailing_space {
      saw_digit = true
      let digit = code.to_int() - ('0' : Char).to_int()
      number = if number > (2147483647 - digit) / 10 {
        2147483647
      } else {
        number * 10 + digit
      }
    } else if code == ' ' || code == '\t' || code == '\n' || code == '\r' {
      if saw_digit {
        trailing_space = true
      }
    } else {
      return None
    }
  }
  if saw_digit {
    Some(number)
  } else {
    None
  }
}

///|
fn define_command_macro(
  context : MacroExpander,
  exists_ok : Bool,
  nonexists_ok : Bool,
  skip_if_exists : Bool,
) -> ParseResult[MacroReplacement] {
  let name_arg = match context.consume_arg(None) {
    Err(err) => return Err(err)
    Ok(value) => value.tokens
  }
  if name_arg.length() != 1 {
    return Err(
      InvalidArgument(
        message="\\newcommand's first argument must be a macro name",
        loc=None,
      ),
    )
  }
  let name = name_arg[0].text
  let exists = context.is_defined(name)
  if exists && !exists_ok {
    return Err(
      InvalidArgument(
        message="\\newcommand{\{name}} attempting to redefine \{name}; use \\renewcommand",
        loc=None,
      ),
    )
  }
  if !exists && !nonexists_ok {
    return Err(
      InvalidArgument(
        message="\\renewcommand{\{name}} when command \{name} does not yet exist; use \\newcommand",
        loc=None,
      ),
    )
  }
  let mut body = match context.consume_arg(None) {
    Err(err) => return Err(err)
    Ok(value) => value.tokens
  }
  let mut num_args = 0
  if body.length() == 1 && body[0].text == "[" {
    let builder = StringBuilder()
    for ;; {
      let token = match context.expand_next_token() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if token.text == "]" || token.text == "EOF" {
        break
      }
      builder.write_string(token.text)
    }
    let count_text = builder.to_string()
    num_args = match parse_argument_count(count_text) {
      Some(value) => value
      None =>
        return Err(
          InvalidArgument(
            message="Invalid number of arguments: \{count_text}",
            loc=None,
          ),
        )
    }
    body = match context.consume_arg(None) {
      Err(err) => return Err(err)
      Ok(value) => value.tokens
    }
  }
  if !(exists && skip_if_exists) {
    context.macros.set(
      name,
      Some(MacroDefinition::expansion(MacroExpansion::make(body, num_args~))),
    )
  }
  Ok(ReplacementText(""))
}

///|
fn new_command_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  define_command_macro(context, false, true, false)
}

///|
fn renew_command_macro(
  context : MacroExpander,
) -> ParseResult[MacroReplacement] {
  define_command_macro(context, true, false, false)
}

///|
fn provide_command_macro(
  context : MacroExpander,
) -> ParseResult[MacroReplacement] {
  define_command_macro(context, true, true, true)
}
