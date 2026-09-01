///|
fn noexpand_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  let token = context.pop_token()
  if context.is_expandable(token.text) {
    token.noexpand = true
    token.treat_as_relax = true
  }
  token_expansion([token])
}

///|
fn expandafter_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  let token = context.pop_token()
  let _ = context.expand_once(expandable_only=true)
  token_expansion([token])
}

///|
fn first_of_two_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  guard context.consume_args(2, None).get(0) is Some(tokens) else {
    raise InternalInvariant(message="Missing first macro argument")
  }
  token_expansion(tokens)
}

///|
fn second_of_two_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  guard context.consume_args(2, None).get(1) is Some(tokens) else {
    raise InternalInvariant(message="Missing second macro argument")
  }
  token_expansion(tokens)
}

///|
fn if_next_char_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  let args = context.consume_args(3, None)
  context.consume_spaces()
  let next = context.future()
  let selected = if args[0].length() == 1 && args[0][0].text == next.text {
    args[1]
  } else {
    args[2]
  }
  token_expansion(selected)
}

///|
fn text_or_math_macro(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  let args = context.consume_args(2, None)
  if context.mode == Text {
    token_expansion(args[0])
  } else {
    token_expansion(args[1])
  }
}
