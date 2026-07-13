///|
fn dots_by_token(name : String) -> String? {
  match name {
    "," => Some("\\dotsc")
    "\\not" => Some("\\dotsb")
    "+"
    | "="
    | "<"
    | ">"
    | "-"
    | "*"
    | ":"
    | "\\DOTSB"
    | "\\coprod"
    | "\\bigvee"
    | "\\bigwedge"
    | "\\biguplus"
    | "\\bigcap"
    | "\\bigcup"
    | "\\prod"
    | "\\sum"
    | "\\bigotimes"
    | "\\bigoplus"
    | "\\bigodot"
    | "\\bigsqcup"
    | "\\And"
    | "\\longrightarrow"
    | "\\Longrightarrow"
    | "\\longleftarrow"
    | "\\Longleftarrow"
    | "\\longleftrightarrow"
    | "\\Longleftrightarrow"
    | "\\mapsto"
    | "\\longmapsto"
    | "\\hookrightarrow"
    | "\\doteq"
    | "\\mathbin"
    | "\\mathrel"
    | "\\relbar"
    | "\\Relbar"
    | "\\xrightarrow"
    | "\\xleftarrow" => Some("\\dotsb")
    "\\DOTSI"
    | "\\int"
    | "\\oint"
    | "\\iint"
    | "\\iiint"
    | "\\iiiint"
    | "\\idotsint" => Some("\\dotsi")
    "\\DOTSX" => Some("\\dotsx")
    _ => None
  }
}

///|
fn space_after_dots(name : String) -> Bool {
  match name {
    ")"
    | "]"
    | "\\rbrack"
    | "\\}"
    | "\\rbrace"
    | "\\rangle"
    | "\\rceil"
    | "\\rfloor"
    | "\\rgroup"
    | "\\rmoustache"
    | "\\right"
    | "\\bigr"
    | "\\biggr"
    | "\\Bigr"
    | "\\Biggr"
    | "$"
    | ";"
    | "."
    | "," => true
    _ => false
  }
}

///|
fn dots_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  let next = match context.expand_after_future() {
    Err(err) => return Err(err)
    Ok(value) => value.text
  }
  let result = match dots_by_token(next) {
    Some(value) => value
    None if starts_with_at(next, 0, "\\not") => "\\dotsb"
    None =>
      match (context.math_symbol_group)(next) {
        Some(BinarySymbol) | Some(RelationSymbol) => "\\dotsb"
        None => "\\dotso"
      }
  }
  Ok(ReplacementText(result))
}

///|
fn dots_other_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.future() {
    Err(err) => Err(err)
    Ok(next) =>
      if space_after_dots(next.text) {
        Ok(ReplacementText("\\ldots\\,"))
      } else {
        Ok(ReplacementText("\\ldots"))
      }
  }
}

///|
fn dots_comma_macro(context : MacroExpander) -> ParseResult[MacroReplacement] {
  match context.future() {
    Err(err) => Err(err)
    Ok(next) =>
      if next.text != "," && space_after_dots(next.text) {
        Ok(ReplacementText("\\ldots\\,"))
      } else {
        Ok(ReplacementText("\\ldots"))
      }
  }
}

///|
fn centered_dots_macro(
  context : MacroExpander,
) -> ParseResult[MacroReplacement] {
  match context.future() {
    Err(err) => Err(err)
    Ok(next) =>
      if space_after_dots(next.text) {
        Ok(ReplacementText("\\@cdots\\,"))
      } else {
        Ok(ReplacementText("\\@cdots"))
      }
  }
}
