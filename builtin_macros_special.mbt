///|
fn tokens_to_text(tokens : Array[Token]) -> String {
  let builder = StringBuilder()
  for token in tokens.rev() {
    builder.write_string(token.text)
  }
  builder.to_string()
}

///|
fn message_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.consume_args(1, None) {
    Err(err) => Err(err)
    Ok(args) => {
      (context.macro_reporter)(MacroMessage(tokens_to_text(args[0])))
      Ok(ReplacementText(""))
    }
  }
}

///|
fn error_message_macro(
  context : MacroExpander,
) -> ParseResult[MacroReplacement] {
  match context.consume_args(1, None) {
    Err(err) => Err(err)
    Ok(args) => {
      (context.macro_reporter)(MacroErrorMessage(tokens_to_text(args[0])))
      Ok(ReplacementText(""))
    }
  }
}

///|
fn show_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.pop_token() {
    Err(err) => Err(err)
    Ok(token) => {
      let status = if context.is_defined(token.text) {
        "defined"
      } else {
        "undefined"
      }
      (context.macro_reporter)(MacroShow("\{token.text}: \{status}"))
      Ok(ReplacementText(""))
    }
  }
}

///|
fn tag_literal_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  if context.macros.has("\\df@tag") {
    Err(InvalidArgument(message="Multiple \\tag", loc=None))
  } else {
    Ok(ReplacementText("\\gdef\\df@tag{\\text{#1}}"))
  }
}

///|
fn restore_dynamic_macro(
  context : MacroExpander,
  name : String,
  old_value : MacroHandler?,
) -> Unit {
  context.dynamic_macros.set(name, old_value)
}

///|
fn braket_separator_handler(
  one : Bool,
  doubled : Bool,
  middle : Array[Token],
  middle_double : Array[Token],
  old_middle : MacroHandler?,
  old_middle_double : MacroHandler?,
) -> MacroHandler {
  fn(context) {
    if one {
      restore_dynamic_macro(context, "|", old_middle)
      if !middle_double.is_empty() {
        restore_dynamic_macro(context, "\\|", old_middle_double)
      }
    }
    let mut use_double = doubled
    if !doubled && !middle_double.is_empty() {
      let next = match context.future() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      if next.text == "|" {
        match context.pop_token() {
          Err(err) => return Err(err)
          Ok(_) => use_double = true
        }
      }
    }
    if use_double {
      Ok(token_expansion(middle_double))
    } else {
      Ok(token_expansion(middle))
    }
  }
}

///|
fn braket_helper(
  context : MacroExpander,
  one : Bool,
) -> ParseResult[MacroReplacement] {
  let parts = match context.consume_args(4, None) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  let left = parts[0]
  let middle = parts[1]
  let middle_double = parts[2]
  let right = parts[3]
  let old_middle = context.dynamic_macros.get_current("|")
  let old_middle_double = context.dynamic_macros.get_current("\\|")
  context.begin_group()
  context.dynamic_macros.set(
    "|",
    Some(
      braket_separator_handler(
        one, false, middle, middle_double, old_middle, old_middle_double,
      ),
    ),
  )
  if !middle_double.is_empty() {
    context.dynamic_macros.set(
      "\\|",
      Some(
        braket_separator_handler(
          one, true, middle, middle_double, old_middle, old_middle_double,
        ),
      ),
    )
  }
  let argument = match context.consume_arg(None) {
    Err(err) => {
      let _ = context.end_group()
      return Err(err)
    }
    Ok(value) => value.tokens
  }
  let input = right.copy()
  input.append(argument)
  input.append(left)
  let expanded = context.expand_tokens(input)
  let close_result = context.end_group()
  match (expanded, close_result) {
    (Err(err), _) => Err(err)
    (Ok(_), Err(err)) => Err(err)
    (Ok(tokens), Ok(_)) => {
      tokens.rev_in_place()
      Ok(token_expansion(tokens))
    }
  }
}

///|
fn braket_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  braket_helper(context, false)
}

///|
fn set_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  braket_helper(context, true)
}
