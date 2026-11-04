///|
fn merged_text_location(first : ParseNode, last : ParseNode) -> SourceLocation? {
  match (first, last) {
    (TextOrd(loc=Some(start), ..), TextOrd(loc=Some(end), ..)) if start.input ==
      end.input => Some(SourceLocation::range(start, end))
    _ => None
  }
}

///|
fn merged_text_ord(
  first : ParseNode,
  last : ParseNode,
  text : String,
) -> ParseNode {
  TextOrd(mode=Text, loc=merged_text_location(first, last), text~)
}

///|
fn form_text_ligatures(body : Array[ParseNode]) -> Array[ParseNode] {
  let output : Array[ParseNode] = []
  for index = 0; index < body.length(); {
    let current = body[index]
    if current is TextOrd(text="-", ..) &&
      body.get(index + 1) is Some(next) &&
      next is TextOrd(text="-", ..) {
      if body.get(index + 2) is Some(last) && last is TextOrd(text="-", ..) {
        output.push(merged_text_ord(current, last, "---"))
        continue index + 3
      }
      output.push(merged_text_ord(current, next, "--"))
      continue index + 2
    }
    if current is TextOrd(text=quote, ..) &&
      (quote == "'" || quote == "`") &&
      body.get(index + 1) is Some(next) &&
      next is TextOrd(text=next_text, ..) &&
      next_text == quote {
      output.push(merged_text_ord(current, next, quote + quote))
      continue index + 2
    }
    output.push(current)
    continue index + 1
  } nobreak {
    output
  }
}
