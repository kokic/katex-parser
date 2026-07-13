///|
fn make_macro_expansion(
  body : String,
  num_args? : Int = 0,
  delimiters? : Array[Array[String]],
  unexpandable? : Bool = false,
) -> MacroExpansion {
  let expander = MacroExpander::make("", Settings::default())
  let lexed = expander.lex_macro_body(body).unwrap()
  match delimiters {
    Some(values) =>
      MacroExpansion::make(
        lexed.tokens,
        num_args~,
        delimiters=values,
        unexpandable~,
      )
    None => MacroExpansion::make(lexed.tokens, num_args~, unexpandable~)
  }
}

///|
fn expanded_text(expander : MacroExpander) -> String {
  let mut output = ""
  for ;; {
    let token = expander.expand_next_token().unwrap()
    if token.text == "EOF" {
      break output
    }
    output = output + token.text
  }
}

///|
fn noexpand_handler(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.pop_token() {
    Err(err) => Err(err)
    Ok(token) => {
      if context.is_expandable(token.text) {
        token.noexpand = true
        token.treat_as_relax = true
      }
      Ok(ReplacementExpansion(MacroExpansion::make([token])))
    }
  }
}

///|
fn mode_handler(context : MacroExpander) -> ParseResult[MacroReplacement] {
  Ok(ReplacementText(if context.mode == Math { "M" } else { "T" }))
}

///|
fn structured_dynamic_handler(
  context : MacroExpander,
) -> ParseResult[MacroReplacement] {
  match context.lex_macro_body("xy") {
    Err(err) => Err(err)
    Ok(expansion) => Ok(ReplacementExpansion(expansion))
  }
}

///|
fn parameter_dynamic_handler(
  _context : MacroExpander,
) -> ParseResult[MacroReplacement] {
  Ok(ReplacementText("#1"))
}

///|
fn settings_with_max_expand(max_expand : Int) -> Settings {
  {
    throw_on_error: true,
    error_color: "#cc0000",
    max_expand,
    global_group: false,
    macros: Map([]),
  }
}

///|
fn test_command_status(name : String) -> ExternalCommandStatus {
  match name {
    "\\expandable" => ExternalExpandable
    "\\primitive" => ExternalUnexpandable
    _ => ExternalUndefined
  }
}
