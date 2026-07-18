///|
/// Renders parsed KaTeX nodes as Unicode text. Nodes without a direct Unicode
/// rendering use UnicodeMath-style function syntax so that their structure is
/// retained in plain text.
pub fn render(
  nodes : Array[@katex_parser.ParseNode],
  config? : RenderConfig = RenderConfig::default(),
) -> String {
  render_internal(nodes, { in_display: false, config })
}

///|
fn render_internal(
  nodes : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> String {
  nodes.map(n => render_node_internal(n, state)).join("")
}

///|
fn render_node_internal(
  node : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  let slash = state.config.fraction_slash
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
      render_internal(body, {
        ..state,
        in_display: state.in_display || style == DisplayStyle,
      })
    Text(body~, ..)
    | MClass(body~, ..)
    | HBox(body~, ..)
    | Sizing(body~, ..)
    | Color(body~, ..)
    | Href(body~, ..)
    | Html(body~, ..)
    | OrdGroup(body~, ..) => render_internal(body, state)
    Sqrt(body~, index=None, ..) => render_radical("", body, state)
    Sqrt(body~, index=Some(index), ..) => render_root(index, body, state)
    Infix(replace_with~, ..) => replace_with
    GenFrac(numer~, denom~, has_bar_line=false, left_delim~, right_delim~, ..) =>
      render_delimited(
        left_delim,
        "\{render_node_internal(numer, state)},\{render_node_internal(denom, state)}",
        right_delim,
      )
    GenFrac(numer~, denom~, left_delim=None, right_delim=None, ..) => {
      guard !state.in_display else { render_genfrac_block(numer, denom, state) }
      "\{render_operand(numer, state)}\{slash}\{render_operand(denom, state)}"
    }
    GenFrac(numer~, denom~, left_delim~, right_delim~, ..) =>
      render_delimited(
        left_delim,
        "\{render_operand(numer, state)}\{slash}\{render_operand(denom, state)}",
        right_delim,
      )
    Font(font~, body~, ..) => render_font(font, body, state)
    Op(content~, ..) => render_operator_content(content, state)
    OperatorName(body~, ..) => render_internal(body, state)
    Overline(body~, ..) => "overline(\{render_node_internal(body, state)})"
    Underline(body~, ..) => "underline(\{render_node_internal(body, state)})"
    Smash(body~, ..)
    | VPhantom(body~, ..)
    | VCenter(body~, ..)
    | RaiseBox(body~, ..)
    | Lap(body~, ..) => render_node_internal(body, state)
    CdParent(fragment~, ..) => render_node_internal(fragment, state)
    Phantom(body~, ..) => "phantom(\{render_internal(body, state)})"
    Pmb(body~, ..) => "bold(\{render_internal(body, state)})"
    Rule(width~, height~, ..) =>
      "rule(\{render_measurement(width)},\{render_measurement(height)})"
    MathChoice(display~, ..) => render_internal(display, state)
    HorizBrace(label~, is_over=true, base~, ..) =>
      "overbrace(\{render_node_internal(base, state)})^\{label}"
    HorizBrace(label~, base~, ..) =>
      "underbrace(\{render_node_internal(base, state)})_\{label}"
    XArrow(label~, body~, below=None, ..) =>
      "xrightarrow(\{render_node_internal(body, state)})^\{label}"
    XArrow(label~, body~, below=Some(below), ..) =>
      "xrightarrow(\{render_node_internal(body, state)})_(\{render_node_internal(below, state)})^\{label}"
    AccentUnder(label~, base~, ..) =>
      "underaccent(\{label},\{render_node_internal(base, state)})"
    DelimSizing(delim~, ..) | LeftRightRight(delim~, ..) | Middle(delim~, ..) =>
      delim
    LeftRight(body~, left~, right~, ..) =>
      if state.in_display && body.length() == 1 {
        match body[0] {
          Array(body~, ..) => render_leftright_block(left, right, body, state)
          _ => "\{left}\{render_internal(body, state)}\{right}"
        }
      } else {
        "\{left}\{render_internal(body, state)}\{right}"
      }
    Kern(dimension~, ..) => "kern(\{render_measurement(dimension)})"
    Enclose(label~, body~, ..) =>
      "\{label}(\{render_node_internal(body, state)})"
    IncludeGraphics(alt~, ..) => "image(\{alt})"
    Tag(body~, tag~, ..) =>
      "\{render_internal(body, state)}\t(\{render_internal(tag, state)})"
    Array(body~, ..) =>
      if state.in_display {
        render_array_block(body, state)
      } else {
        render_array_inline(body, state)
      }
    CdLabel(side~, label~, ..) =>
      "\{side}(\{render_node_internal(label, state)})"
    Cr(new_line=true, ..) => "\n"
    Cr(..) => ""
    HtmlMathML(mathml~, ..) => render_internal(mathml, state)
    SupSub(base~, sup~, sub~, ..) => render_sup_sub(base, sup, sub, state)
    Accent(label~, base~, ..) => render_accent(label, base, state)
    Verb(body~, ..) => body
  }
}

///|
fn render_operator_content(
  content : @katex_parser.OperatorContent,
  state : RenderState,
) -> String {
  match content {
    SymbolOperator(text) | NamedOperator(text) => text
    BodyOperator(body) => render_internal(body, state)
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
  state : RenderState,
) -> String {
  if font == "mathrm" || font == "mathnormal" {
    return render_node_internal(body, state)
  }
  match body {
    MathOrd(text~, ..) | TextOrd(text~, ..) | Atom(text~, ..) =>
      match @katex_parser.unicode_font_character(font, text) {
        Some(char) => char
        None => "\{font}(\{render_node_internal(body, state)})"
      }
    _ => "\{font}(\{render_node_internal(body, state)})"
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
  "\{left}\{content}\{right}"
}

///|
fn render_measurement(measurement : @katex_parser.Measurement) -> String {
  "\{measurement.number}\{measurement.unit}"
}

///|
fn render_root(
  index : @katex_parser.ParseNode,
  body : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  let index_text = render_node_internal(index, state)
  match unicode_script(index_text, UnicodeSuperscript) {
    Some(index) => render_radical(index, body, state)
    None => "root(\{index_text},\{render_node_internal(body, state)})"
  }
}

///|
fn render_radical(
  prefix : String,
  body : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  "\{prefix}√\{render_operand(body, state)}"
}

///|
/// Renders an expression where precedence must remain visible in plain text.
fn render_operand(
  node : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  let rendered = render_node_internal(node, state)
  guard is_atomic_expression(node) else { "(\{rendered})" }
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
  state : RenderState,
) -> String {
  let base = base.map(b => render_operand(b, state)).unwrap_or_default()
  let sub = render_script(sub, UnicodeSubscript, "_", state)
  let sup = render_script(sup, UnicodeSuperscript, "^", state)
  "\{base}\{sub}\{sup}"
}

///|
fn render_script(
  node : @katex_parser.ParseNode?,
  kind : @katex_parser.UnicodeScriptKind,
  fallback_prefix : String,
  state : RenderState,
) -> String {
  node
  .map(node => {
    let default = () => "\{fallback_prefix}\{render_operand(node, state)}"
    unicode_script(render_node_internal(node, state), kind).unwrap_or_else(
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
  let acc0 : String? = Some("")
  text.fold(init=acc0, (acc, character) => {
    match acc {
      None => None
      Some(s) => {
        let ch = String::from_array([character])
        match @katex_parser.unicode_script_character(kind, ch) {
          Some(script) => Some("\{s}\{script}")
          None => None
        }
      }
    }
  })
}

///|
fn render_accent(
  label : String,
  base : @katex_parser.ParseNode,
  state : RenderState,
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
      "\{render_node_internal(base, state)}\{mark}"
    _ => "\{label}(\{render_node_internal(base, state)})"
  }
}
