///|
fn tokens_to_text(tokens : Array[Token]) -> String {
  let builder = StringBuilder()
  for token in tokens.rev() {
    builder.write_string(token.text)
  }
  builder.to_string()
}

///|
fn message_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  let args = context.consume_args(1, None)
  (context.macro_reporter)(MacroMessage(tokens_to_text(args[0])))
  ReplacementText("")
}

///|
fn error_message_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  let args = context.consume_args(1, None)
  (context.macro_reporter)(MacroErrorMessage(tokens_to_text(args[0])))
  ReplacementText("")
}

///|
fn show_macro(context : MacroExpander) -> MacroReplacement raise ParseFailure {
  let token = context.pop_token()
  let status = if context.is_defined(token.text) {
    "defined"
  } else {
    "undefined"
  }
  (context.macro_reporter)(MacroShow("\{token.text}: \{status}"))
  ReplacementText("")
}

///|
fn tag_literal_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  if context.macros.has("\\df@tag") {
    raise InvalidArgument(message="Multiple \\tag", loc=None)
  } else {
    ReplacementText("\\gdef\\df@tag{\\text{#1}}")
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
  context => {
    if one {
      restore_dynamic_macro(context, "|", old_middle)
      if !middle_double.is_empty() {
        restore_dynamic_macro(context, "\\|", old_middle_double)
      }
    }
    let mut use_double = doubled
    if !doubled && !middle_double.is_empty() {
      let next = context.future()
      if next.text == "|" {
        let _ = context.pop_token()
        use_double = true
      }
    }
    if use_double {
      token_expansion(middle_double)
    } else {
      token_expansion(middle)
    }
  }
}

///|
fn braket_helper(
  context : MacroExpander,
  one : Bool,
) -> MacroReplacement raise ParseFailure {
  let parts = context.consume_args(4, None)
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
  let expanded : Result[Array[Token], ParseFailure] = Ok(
    {
      let argument = context.consume_arg(None).tokens
      let input = right.copy()
      input.append(argument)
      input.append(left)
      context.expand_tokens(input)
    },
  ) catch {
    err => Err(err)
  }
  let close_result : Result[Unit, ParseFailure] = Ok(context.end_group()) catch {
    err => Err(err)
  }
  match (expanded, close_result) {
    (Err(err), _) => raise err
    (Ok(_), Err(err)) => raise err
    (Ok(tokens), Ok(_)) => {
      tokens.rev_in_place()
      token_expansion(tokens)
    }
  }
}

///|
fn braket_macro(context : MacroExpander) -> MacroReplacement raise ParseFailure {
  braket_helper(context, false)
}

///|
fn set_macro(context : MacroExpander) -> MacroReplacement raise ParseFailure {
  braket_helper(context, true)
}
