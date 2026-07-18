///|
/// Renders parsed KaTeX nodes as Unicode text. Nodes without a direct Unicode
/// rendering use UnicodeMath-style function syntax so that their structure is
/// retained in plain text.
pub fn render(nodes : Array[@katex_parser.ParseNode]) -> String {
  render_internal(nodes, false)
}

///|
fn render_internal(
  nodes : Array[@katex_parser.ParseNode],
  in_display : Bool,
) -> String {
  nodes.map(n => render_node_internal(n, in_display)).join("")
}

///|
fn render_node_internal(
  node : @katex_parser.ParseNode,
  in_display : Bool,
) -> String {
  match node {
    Internal(..) | EnvironmentEnd(..) => ""
    Raw(string~, ..) => render_symbol(string)
    ColorToken(color~, ..) => render_symbol(color)
    TextOrd(text~, ..)
    | MathOrd(text~, ..)
    | Spacing(text~, ..)
    | AccentToken(text~, ..)
    | OperatorToken(text~, ..)
    | Atom(text~, ..) => render_symbol(text)
    Size(value~, ..) => render_measurement(value)
    Url(url~, ..) => url
    Styling(body~, style~, ..) =>
      render_internal(body, in_display || style == DisplayStyle)
    Text(body~, ..)
    | MClass(body~, ..)
    | HBox(body~, ..)
    | Sizing(body~, ..)
    | Color(body~, ..)
    | Href(body~, ..)
    | Html(body~, ..)
    | OrdGroup(body~, ..) => render_internal(body, in_display)
    Sqrt(body~, index=None, ..) => render_radical("", body, in_display)
    Sqrt(body~, index=Some(index), ..) => render_root(index, body, in_display)
    Infix(replace_with~, ..) => replace_with
    GenFrac(numer~, denom~, has_bar_line=false, left_delim~, right_delim~, ..) =>
      render_delimited(
        left_delim,
        render_node_internal(numer, in_display) +
        "," +
        render_node_internal(denom, in_display),
        right_delim,
      )
    GenFrac(numer~, denom~, left_delim~, right_delim~, ..) =>
      render_delimited(
        left_delim,
        render_operand(numer, in_display) +
        "∕" +
        render_operand(denom, in_display),
        right_delim,
      )
    Font(font~, body~, ..) => render_font(font, body, in_display)
    Op(content~, ..) => render_operator_content(content, in_display)
    OperatorName(body~, ..) => render_internal(body, in_display)
    Overline(body~, ..) => "overline(" + render_node_internal(body, in_display) + ")"
    Underline(body~, ..) => "underline(" + render_node_internal(body, in_display) + ")"
    Smash(body~, ..)
    | VPhantom(body~, ..)
    | VCenter(body~, ..)
    | RaiseBox(body~, ..)
    | Lap(body~, ..) => render_node_internal(body, in_display)
    CdParent(fragment~, ..) => render_node_internal(fragment, in_display)
    Phantom(body~, ..) => "phantom(" + render_internal(body, in_display) + ")"
    Pmb(body~, ..) => "bold(" + render_internal(body, in_display) + ")"
    Rule(width~, height~, ..) =>
      "rule(" +
      render_measurement(width) +
      "," +
      render_measurement(height) +
      ")"
    MathChoice(display~, ..) => render_internal(display, in_display)
    HorizBrace(label~, is_over=true, base~, ..) =>
      "overbrace(" + render_node_internal(base, in_display) + ")^" + label
    HorizBrace(label~, base~, ..) =>
      "underbrace(" + render_node_internal(base, in_display) + ")_" + label
    XArrow(label~, body~, below=None, ..) =>
      "xrightarrow(" + render_node_internal(body, in_display) + ")^" + label
    XArrow(label~, body~, below=Some(below), ..) =>
      "xrightarrow(" +
      render_node_internal(body, in_display) +
      ")_(" +
      render_node_internal(below, in_display) +
      ")^" +
      label
    AccentUnder(label~, base~, ..) =>
      "underaccent(" + label + "," + render_node_internal(base, in_display) + ")"
    DelimSizing(delim~, ..) | LeftRightRight(delim~, ..) | Middle(delim~, ..) =>
      delim
    LeftRight(body~, left~, right~, ..) =>
      if in_display && body.length() == 1 {
        match body[0] {
          Array(body~, ..) =>
            render_leftright_block(left, right, body, in_display)
          _ => left + render_internal(body, in_display) + right
        }
      } else {
        left + render_internal(body, in_display) + right
      }
    Kern(dimension~, ..) => "kern(" + render_measurement(dimension) + ")"
    Enclose(label~, body~, ..) => label + "(" + render_node_internal(body, in_display) + ")"
    IncludeGraphics(alt~, ..) => "image(" + alt + ")"
    Tag(body~, tag~, ..) =>
      render_internal(body, in_display) +
      "\t(" +
      render_internal(tag, in_display) +
      ")"
    Array(body~, ..) =>
      if in_display {
        render_array_block(body, in_display)
      } else {
        render_array_inline(body, in_display)
      }
    CdLabel(side~, label~, ..) =>
      side + "(" + render_node_internal(label, in_display) + ")"
    Cr(new_line=true, ..) => "\n"
    Cr(..) => ""
    HtmlMathML(mathml~, ..) => render_internal(mathml, in_display)
    SupSub(base~, sup~, sub~, ..) => render_sup_sub(base, sup, sub, in_display)
    Accent(label~, base~, ..) => render_accent(label, base, in_display)
    Verb(body~, ..) => body
  }
}

///|
fn render_array_inline(
  body : Array[Array[@katex_parser.ParseNode]],
  in_display : Bool,
) -> String {
  body.map(r => render_row(r, in_display)).join("; ")
}

///|
fn render_array_block(
  body : Array[Array[@katex_parser.ParseNode]],
  in_display : Bool,
) -> String {
  let rows = render_array_rows(body, in_display)
  rows.join("\n")
}

///|
fn render_array_rows(
  body : Array[Array[@katex_parser.ParseNode]],
  in_display : Bool,
) -> Array[String] {
  let cell_texts = body.map(
    r => r.map(c => render_node_internal(c, in_display)),
  )
  let widths = column_widths(cell_texts)
  cell_texts.map(row => {
    let mut result = ""
    let mut j = 0
    let n = row.length()
    while j < n {
      result = result + pad_right(row[j], widths[j])
      j = j + 1
      if j < n {
        result = result + "  "
      }
    }
    result
  })
}

///|
fn render_leftright_block(
  left : String,
  right : String,
  body : Array[Array[@katex_parser.ParseNode]],
  in_display : Bool,
) -> String {
  let rows = render_array_rows(body, in_display)
  rows.map(row => left + row + right).join("\n")
}

///|
fn column_widths(cells : Array[Array[String]]) -> Array[Int] {
  let mut max_cols = 0
  let mut i = 0
  while i < cells.length() {
    let len = cells[i].length()
    if len > max_cols {
      max_cols = len
    }
    i = i + 1
  }
  let widths = Array::make(max_cols, 0)
  let mut r = 0
  while r < cells.length() {
    let row = cells[r]
    let mut c = 0
    while c < row.length() {
      let w = row[c].length()
      if w > widths[c] {
        widths[c] = w
      }
      c = c + 1
    }
    r = r + 1
  }
  widths
}

///|
fn pad_right(s : String, width : Int) -> String {
  let need = width - s.length()
  if need <= 0 {
    return s
  }
  let mut spaces = ""
  let mut i = 0
  while i < need {
    spaces = spaces + " "
    i = i + 1
  }
  s + spaces
}

///|
fn render_row(
  row : Array[@katex_parser.ParseNode],
  in_display : Bool,
) -> String {
  row.map(c => render_node_internal(c, in_display)).join(", ")
}

///|
fn render_operator_content(
  content : @katex_parser.OperatorContent,
  in_display : Bool,
) -> String {
  match content {
    SymbolOperator(text) | NamedOperator(text) => text
    BodyOperator(body) => render_internal(body, in_display)
  }
}

///|
fn render_symbol(text : String) -> String {
  match @katex_parser.unicode_symbol(text) {
    Some(symbol) => symbol
    None => text
  }
}

///|
fn render_font(
  font : String,
  body : @katex_parser.ParseNode,
  in_display : Bool,
) -> String {
  if font == "mathrm" || font == "mathnormal" {
    return render_node_internal(body, in_display)
  }
  match body {
    MathOrd(text~, ..) | TextOrd(text~, ..) | Atom(text~, ..) =>
      match @katex_parser.unicode_font_character(font, text) {
        Some(char) => char
        None => font + "(" + render_node_internal(body, in_display) + ")"
      }
    _ => font + "(" + render_node_internal(body, in_display) + ")"
  }
}

///|
fn render_delimited(
  left : String?,
  content : String,
  right : String?,
) -> String {
  let left = left.unwrap_or_default()
  let right = right.unwrap_or_default()
  left + content + right
}

///|
fn render_measurement(measurement : @katex_parser.Measurement) -> String {
  measurement.number.to_string() + measurement.unit
}

///|
fn render_root(
  index : @katex_parser.ParseNode,
  body : @katex_parser.ParseNode,
  in_display : Bool,
) -> String {
  let index_text = render_node_internal(index, in_display)
  match unicode_script(index_text, UnicodeSuperscript) {
    Some(index) => render_radical(index, body, in_display)
    None => "root(" + index_text + "," + render_node_internal(body, in_display) + ")"
  }
}

///|
fn render_radical(
  prefix : String,
  body : @katex_parser.ParseNode,
  in_display : Bool,
) -> String {
  prefix + "√" + render_operand(body, in_display)
}

///|
/// Renders an expression where precedence must remain visible in plain text.
fn render_operand(
  node : @katex_parser.ParseNode,
  in_display : Bool,
) -> String {
  let rendered = render_node_internal(node, in_display)
  guard is_atomic_expression(node) else { "(" + rendered + ")" }
  rendered
}

///|
/// True if the Unicode rendering has no internal operator that needs grouping.
fn is_atomic_expression(node : @katex_parser.ParseNode) -> Bool {
  match node {
    Raw(..)
    | ColorToken(..)
    | TextOrd(..)
    | MathOrd(..)
    | Spacing(..)
    | AccentToken(..)
    | OperatorToken(..)
    | Atom(..)
    | Op(..)
    | OperatorName(..)
    | LeftRight(..) => true
    Styling(body~, ..)
    | Text(body~, ..)
    | MClass(body~, ..)
    | HBox(body~, ..)
    | Sizing(body~, ..)
    | Color(body~, ..)
    | Href(body~, ..)
    | Html(body~, ..)
    | OrdGroup(body~, ..) => body.length() == 1 && is_atomic_expression(body[0])
    Accent(base~, ..) => is_atomic_expression(base)
    _ => false
  }
}

///|
fn render_sup_sub(
  base : @katex_parser.ParseNode?,
  sup : @katex_parser.ParseNode?,
  sub : @katex_parser.ParseNode?,
  in_display : Bool,
) -> String {
  let base =
    base
    .map(b => render_operand(b, in_display))
    .unwrap_or_default()
  let sub = render_script(sub, UnicodeSubscript, "_", in_display)
  let sup = render_script(sup, UnicodeSuperscript, "^", in_display)
  base + sub + sup
}

///|
fn render_script(
  node : @katex_parser.ParseNode?,
  kind : @katex_parser.UnicodeScriptKind,
  fallback_prefix : String,
  in_display : Bool,
) -> String {
  node
  .map(node => {
    let default = () =>
      fallback_prefix + render_operand(node, in_display)
    unicode_script(render_node_internal(node, in_display), kind).unwrap_or_else(
      default,
    )
  })
  .unwrap_or_default()
}

///|
fn unicode_script(
  text : String,
  kind : @katex_parser.UnicodeScriptKind,
) -> String? {
  let mut rendered = ""
  for character in text {
    let character = String::from_array([character])
    match @katex_parser.unicode_script_character(kind, character) {
      Some(script) => rendered = rendered + script
      None => return None
    }
  }
  Some(rendered)
}

///|
fn render_accent(
  label : String,
  base : @katex_parser.ParseNode,
  in_display : Bool,
) -> String {
  let mark = match label {
    "\\acute" => Some("́")
    "\\grave" => Some("̀")
    "\\ddot" => Some("̈")
    "\\tilde" => Some("̃")
    "\\bar" => Some("̄")
    "\\breve" => Some("̆")
    "\\check" => Some("̌")
    "\\hat" => Some("̂")
    "\\dot" => Some("̇")
    "\\mathring" => Some("̊")
    "\\vec" => Some("⃗")
    _ => None
  }
  match mark {
    Some(mark) if is_atomic_expression(base) =>
      render_node_internal(base, in_display) + mark
    _ => label + "(" + render_node_internal(base, in_display) + ")"
  }
}
