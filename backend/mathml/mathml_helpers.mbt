///|
fn stretchy(label : String) -> MathMlNode {
  let value = match label {
    "\\widehat" => "^"
    "\\widecheck" => "ˇ"
    "\\widetilde" | "\\utilde" => "~"
    "\\overleftarrow" | "\\underleftarrow" | "\\xleftarrow" | "\\cdleftarrow" =>
      "←"
    "\\overrightarrow"
    | "\\underrightarrow"
    | "\\xrightarrow"
    | "\\cdrightarrow" => "→"
    "\\overbrace" => "⏞"
    "\\underbrace" => "⏟"
    "\\overbracket" => "⎴"
    "\\underbracket" => "⎵"
    "\\overleftrightarrow" | "\\underleftrightarrow" | "\\xleftrightarrow" =>
      "↔"
    "\\Overrightarrow" | "\\xRightarrow" => "⇒"
    "\\xLeftarrow" => "⇐"
    "\\xLeftrightarrow" => "⇔"
    "\\xmapsto" => "↦"
    "\\xlongequal" | "\\cdlongequal" => "="
    _ => symbol(label)
  }
  element("mo", children=[text_node(value)], attributes=[("stretchy", "true")])
}

///|
fn measurement(value : @katex_parser.Measurement) -> String {
  if value.unit == "mu" {
    (value.number / 18.0).to_string() + "em"
  } else {
    value.number.to_string() + value.unit
  }
}

///|
fn size_multiplier(size : Int) -> String {
  let values : Array[String] = [
    "0.5em", "0.6em", "0.7em", "0.8em", "0.9em", "1em", "1.2em", "1.44em", "1.728em",
    "2.074em", "2.488em",
  ]
  if size >= 1 && size <= values.length() {
    values[size - 1]
  } else {
    "1em"
  }
}

///|
fn symbol(value : String) -> String {
  @katex_parser.unicode_symbol(value).unwrap_or(value)
}

///|
fn strip_command(value : String) -> String {
  value.replace(old="\\", new="")
}

///|
fn contains_ascii_digit(value : String) -> Bool {
  for character in value {
    guard character >= '0' && character <= '9' else { continue }
    return true
  }
  false
}

///|
fn verb_text(value : String, star : Bool) -> String {
  value.replace_all(old=" ", new=if star { "␣" } else { " " })
}
