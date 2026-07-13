///|
fn noexpand_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.pop_token() {
    Err(err) => Err(err)
    Ok(token) => {
      if context.is_expandable(token.text) {
        token.noexpand = true
        token.treat_as_relax = true
      }
      Ok(token_expansion([token]))
    }
  }
}

///|
fn expandafter_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  let token = match context.pop_token() {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match context.expand_once(expandable_only=true) {
    Err(err) => Err(err)
    Ok(_) => Ok(token_expansion([token]))
  }
}

///|
fn first_of_two_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.consume_args(2, None) {
    Err(err) => Err(err)
    Ok(args) =>
      match args.get(0) {
        Some(tokens) => Ok(token_expansion(tokens))
        None => Err(InternalInvariant(message="Missing first macro argument"))
      }
  }
}

///|
fn second_of_two_macro(
  context : MacroExpander,
) -> ParseResult[MacroReplacement] {
  match context.consume_args(2, None) {
    Err(err) => Err(err)
    Ok(args) =>
      match args.get(1) {
        Some(tokens) => Ok(token_expansion(tokens))
        None => Err(InternalInvariant(message="Missing second macro argument"))
      }
  }
}

///|
fn if_next_char_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  let args = match context.consume_args(3, None) {
    Err(err) => return Err(err)
    Ok(value) => value
  }
  match context.consume_spaces() {
    Err(err) => Err(err)
    Ok(_) => {
      let next = match context.future() {
        Err(err) => return Err(err)
        Ok(value) => value
      }
      let selected = if args[0].length() == 1 && args[0][0].text == next.text {
        args[1]
      } else {
        args[2]
      }
      Ok(token_expansion(selected))
    }
  }
}

///|
fn text_or_math_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.consume_args(2, None) {
    Err(err) => Err(err)
    Ok(args) =>
      if context.mode == Text {
        Ok(token_expansion(args[0]))
      } else {
        Ok(token_expansion(args[1]))
      }
  }
}
