///|
fn make_macro_expansion(
  body : String,
  num_args? : Int = 0,
  delimiters? : Array[Array[String]],
  unexpandable? : Bool = false,
) -> MacroExpansion raise ParseFailure {
  let expander = MacroExpander::make("", Settings::default())
  let lexed = expander.lex_macro_body(body)
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
fn expanded_text(expander : MacroExpander) -> String raise ParseFailure {
  let mut output = ""
  for ;; {
    let token = expander.expand_next_token()
    if token.text == "EOF" {
      break output
    }
    output = output + token.text
  }
}

///|
fn noexpand_handler(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  let token = context.pop_token()
  if context.is_expandable(token.text) {
    token.noexpand = true
    token.treat_as_relax = true
  }
  ReplacementExpansion(MacroExpansion::make([token]))
}

///|
fn mode_handler(context : MacroExpander) -> MacroReplacement {
  ReplacementText(if context.mode == Math { "M" } else { "T" })
}

///|
fn structured_dynamic_handler(
  context : MacroExpander,
) -> MacroReplacement raise ParseFailure {
  ReplacementExpansion(context.lex_macro_body("xy"))
}

///|
fn parameter_dynamic_handler(_context : MacroExpander) -> MacroReplacement {
  ReplacementText("#1")
}

///|
fn[T] capture_parse_result(
  operation : () -> T raise ParseFailure,
) -> Result[T, ParseFailure] {
  Ok(operation()) catch {
    err => Err(err)
  }
}

///|
fn settings_with_max_expand(max_expand : Int) -> Settings {
  {
    throw_on_error: true,
    error_color: "#cc0000",
    color_is_text_color: false,
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

///|
fn test_string_fingerprint(text : String) -> Int64 {
  let modulus : Int64 = 2147483647
  let mut hash : Int64 = 0
  for index in 0..<text.length() {
    hash = (hash * 131 + Int64::from_int(text[index].to_int())) % modulus
  }
  hash
}
