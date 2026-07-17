///|
/// Renders parsed KaTeX nodes as Unicode text. Nodes without a direct Unicode
/// rendering use UnicodeMath-style function syntax so that their structure is
/// retained in plain text.
pub fn render(nodes : Array[@katex_parser.ParseNode]) -> String {
  nodes.map(render_node).join("")
}

///|
fn render_node(node : @katex_parser.ParseNode) -> String {
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
    Styling(body~, ..)
    | Text(body~, ..)
    | MClass(body~, ..)
    | HBox(body~, ..)
    | Sizing(body~, ..)
    | Color(body~, ..)
    | Href(body~, ..)
    | Html(body~, ..)
    | OrdGroup(body~, ..) => render(body)
    Sqrt(body~, index=None, ..) => render_radical("", body)
    Sqrt(body~, index=Some(index), ..) => render_root(index, body)
    Infix(replace_with~, ..) => replace_with
    GenFrac(numer~, denom~, has_bar_line=false, left_delim~, right_delim~, ..) =>
      render_delimited(
        left_delim,
        render_node(numer) + "," + render_node(denom),
        right_delim,
      )
    GenFrac(numer~, denom~, left_delim~, right_delim~, ..) =>
      render_delimited(
        left_delim,
        render_operand(numer) + "∕" + render_operand(denom),
        right_delim,
      )
    Font(font~, body~, ..) => font + "(" + render_node(body) + ")"
    Op(content~, ..) => render_operator_content(content)
    OperatorName(body~, ..) => render(body)
    Overline(body~, ..) => "overline(" + render_node(body) + ")"
    Underline(body~, ..) => "underline(" + render_node(body) + ")"
    Smash(body~, ..)
    | VPhantom(body~, ..)
    | VCenter(body~, ..)
    | RaiseBox(body~, ..)
    | Lap(body~, ..) => render_node(body)
    CdParent(fragment~, ..) => render_node(fragment)
    Phantom(body~, ..) => "phantom(" + render(body) + ")"
    Pmb(body~, ..) => "bold(" + render(body) + ")"
    Rule(width~, height~, ..) =>
      "rule(" +
      render_measurement(width) +
      "," +
      render_measurement(height) +
      ")"
    MathChoice(display~, ..) => render(display)
    HorizBrace(label~, is_over=true, base~, ..) =>
      "overbrace(" + render_node(base) + ")^" + label
    HorizBrace(label~, base~, ..) =>
      "underbrace(" + render_node(base) + ")_" + label
    XArrow(label~, body~, below=None, ..) =>
      "xrightarrow(" + render_node(body) + ")^" + label
    XArrow(label~, body~, below=Some(below), ..) =>
      "xrightarrow(" +
      render_node(body) +
      ")_(" +
      render_node(below) +
      ")^" +
      label
    AccentUnder(label~, base~, ..) =>
      "underaccent(" + label + "," + render_node(base) + ")"
    DelimSizing(delim~, ..) | LeftRightRight(delim~, ..) | Middle(delim~, ..) =>
      delim
    LeftRight(body~, left~, right~, ..) => left + render(body) + right
    Kern(dimension~, ..) => "kern(" + render_measurement(dimension) + ")"
    Enclose(label~, body~, ..) => label + "(" + render_node(body) + ")"
    IncludeGraphics(alt~, ..) => "image(" + alt + ")"
    Tag(body~, tag~, ..) => render(body) + "\t(" + render(tag) + ")"
    Array(body~, ..) => body.map(render_row).join("\n")
    CdLabel(side~, label~, ..) => side + "(" + render_node(label) + ")"
    Cr(new_line=true, ..) => "\n"
    Cr(..) => ""
    HtmlMathML(mathml~, ..) => render(mathml)
    SupSub(base~, sup~, sub~, ..) => render_sup_sub(base, sup, sub)
    Accent(label~, base~, ..) => render_accent(label, base)
    Verb(body~, ..) => body
  }
}

///|
fn render_row(row : Array[@katex_parser.ParseNode]) -> String {
  render(row)
}

///|
fn render_operator_content(content : @katex_parser.OperatorContent) -> String {
  match content {
    SymbolOperator(text) | NamedOperator(text) => text
    BodyOperator(body) => render(body)
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
) -> String {
  let index_text = render_node(index)
  match unicode_script(index_text, UnicodeSuperscript) {
    Some(index) => render_radical(index, body)
    None => "root(" + index_text + "," + render_node(body) + ")"
  }
}

///|
fn render_radical(prefix : String, body : @katex_parser.ParseNode) -> String {
  prefix + "√" + render_operand(body)
}

///|
/// Renders an expression where precedence must remain visible in plain text.
fn render_operand(node : @katex_parser.ParseNode) -> String {
  let rendered = render_node(node)
  if is_atomic_expression(node) {
    rendered
  } else {
    "(" + rendered + ")"
  }
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
) -> String {
  let base = base.map(render_operand).unwrap_or_default()
  let sub = render_script(sub, UnicodeSubscript, "_")
  let sup = render_script(sup, UnicodeSuperscript, "^")
  base + sub + sup
}

///|
fn render_script(
  node : @katex_parser.ParseNode?,
  kind : @katex_parser.UnicodeScriptKind,
  fallback_prefix : String,
) -> String {
  node
  .map(node => {
    let text = render_node(node)
    match unicode_script(text, kind) {
      Some(rendered) => rendered
      None => fallback_prefix + render_operand(node)
    }
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
fn render_accent(label : String, base : @katex_parser.ParseNode) -> String {
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
    Some(mark) if is_atomic_expression(base) => render_node(base) + mark
    _ => label + "(" + render_node(base) + ")"
  }
}
