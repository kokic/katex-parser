///|
///|
fn render_styling(
  body : Array[@katex_parser.ParseNode],
  style : @katex_parser.StyleLevel,
) -> String {
  match style {
    TextStyle =>
      // Text style is the default; only a `\tfrac`-style fraction needs an
      // explicit `inline(...)`.
      match body {
        [genfrac] if genfrac is @katex_parser.ParseNode::GenFrac(..) =>
          "inline(\{wrap_arg(render_nodes(body, { style: TextStyle, }))})"
        _ => render_nodes(body, { style: TextStyle, })
      }
    _ => {
      let content = wrap_arg(render_nodes(body, { style, }))
      if content == "" {
        ""
      } else {
        match style {
          DisplayStyle => "display(\{content})"
          ScriptStyle => "script(\{content})"
          ScriptScriptStyle => "sscript(\{content})"
          TextStyle => content
        }
      }
    }
  }
}

///|
/// KaTeX `\tiny`..`\Huge` sizes, including the 11-entry `\sixptsize` layout.
/// The `Sizing` node's `size` is 1-based (`sizing_index` returns `index + 1`),
/// so it indexes this table with `size - 1`.
let sizing_sizes : Array[Double] = [
  0.5, 0.5, 0.7, 0.8, 0.9, 1.0, 1.2, 1.44, 1.728, 2.074, 2.488,
]

///|
fn render_sizing(
  size : Int,
  body : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> String {
  let index = size - 1
  let em = if index >= 0 && index < sizing_sizes.length() {
    sizing_sizes[index]
  } else {
    1.0
  }
  "text(size: #\{em}em, \{render_nodes(body, state)})"
}

///|
fn render_sup_sub(
  base : @katex_parser.ParseNode?,
  sup : @katex_parser.ParseNode?,
  sub : @katex_parser.ParseNode?,
  state : RenderState,
) -> String {
  match base {
    None => {
      let sup_str = sup.map_or("", node =>
        "^\{wrap_script(render_node(node, state))}"
      )
      let sub_str = sub.map_or("", node =>
        "_\{wrap_script(render_node(node, state))}"
      )
      "zws\{sup_str}\{sub_str}"
    }
    Some(node) =>
      match node {
        @katex_parser.ParseNode::HorizBrace(label~, base=brace_base, ..) =>
          render_folded_brace(label, brace_base, sup, sub, state)
        @katex_parser.ParseNode::XArrow(label~, body~, below~, ..) =>
          render_folded_arrow(label, body, below, sup, sub, state)
        @katex_parser.ParseNode::Op(
          content=BodyOperator(_),
          limits=true,
          ..
        )
        | @katex_parser.ParseNode::OperatorName(limits=true, ..) => {
          // `\overset`/`\underset`/`\operatorname*` attach their scripts as
          // limits above/below the operator.
          let base_str = render_node(node, state)
          let t_str = sup.map_or("", node =>
            ", t: \{wrap_arg(render_node(node, state))}"
          )
          let b_str = sub.map_or("", node =>
            ", b: \{wrap_arg(render_node(node, state))}"
          )
          "attach(\{base_str}\{t_str}\{b_str})"
        }
        _ => {
          let base_str = render_node(node, state)
          let sup_str = sup.map_or("", node =>
            "^\{wrap_script(render_node(node, state))}"
          )
          let sub_str = sub.map_or("", node =>
            "_\{wrap_script(render_node(node, state))}"
          )
          "\{base_str}\{sup_str}\{sub_str}"
        }
      }
  }
}

///|
/// Script operands may be wrapped in parentheses: Typst strips them in `^`/`_`
/// position, so they are a safe way to group content containing separators or
/// multiple items (a top-level space means the operand spans several atoms and
/// would otherwise bind only the first one).
fn wrap_script(content : String) -> String {
  if contains_script_separator(content) {
    "(\{content})"
  } else {
    content
  }
}

///|
fn contains_script_separator(text : String) -> Bool {
  let mut depth = 0
  let mut in_string = false
  for c in text {
    if c == '"' {
      in_string = !in_string
    } else if !in_string {
      if c == '(' || c == '[' || c == '{' {
        depth = depth + 1
      } else if c == ')' || c == ']' || c == '}' {
        depth = depth - 1
      } else if depth == 0 {
        if c == ' ' || c == '=' || c == ',' || c == ';' ||
          c == ':' || c == '^' || c == '_' {
          return true
        }
      }
    }
  }
  false
}

///|
/// `\overbrace{x}^{label}` folds into `attach(overbrace(x), t: label)` since
/// Typst attaches the label relative to the brace.
fn render_folded_brace(
  label : String,
  body : @katex_parser.ParseNode,
  sup : @katex_parser.ParseNode?,
  sub : @katex_parser.ParseNode?,
  state : RenderState,
) -> String {
  let brace = horiz_brace_name(label)
  let body_str = wrap_arg(render_node(body, state))
  let t_str = sup.map_or("", node => ", t: \{wrap_arg(render_node(node, state))}")
  let b_str = sub.map_or("", node => ", b: \{wrap_arg(render_node(node, state))}")
  "attach(\{brace}(\{body_str})\{t_str}\{b_str})"
}

///|
fn render_folded_arrow(
  label : String,
  body : @katex_parser.ParseNode,
  below : @katex_parser.ParseNode?,
  sup : @katex_parser.ParseNode?,
  sub : @katex_parser.ParseNode?,
  state : RenderState,
) -> String {
  let arrow = xarrow_name(label)
  let body_str = wrap_arg(render_node(body, state))
  let t_str = sup.map_or(body_str, node =>
    "\{wrap_arg(render_node(node, state))}, t: \{wrap_arg(render_node(body, state))}"
  )
  let b_str = match below {
    Some(node) => ", b: \{wrap_arg(render_node(node, state))}"
    None => sub.map_or("", node => ", b: \{wrap_arg(render_node(node, state))}")
  }
  "attach(\{arrow}, t: \{t_str}\{b_str})"
}

///|
fn render_genfrac(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  has_bar_line : Bool,
  left_delim : String?,
  right_delim : String?,
  state : RenderState,
) -> String {
  let num = wrap_arg(render_node(numer, state))
  let den = wrap_arg(render_node(denom, state))
  if !has_bar_line && left_delim is Some(_) && right_delim is Some(_) {
    "binom(\{num}, \{den})"
  } else if (has_bar_line && left_delim is Some(_)) || right_delim is Some(_) {
    let frac = "frac(\{num}, \{den})"
    render_delimited(frac, left_delim, right_delim)
  } else {
    "frac(\{num}, \{den})"
  }
}

///|
/// Wraps content in the given delimiters using a fixed-size `lr`. Used for
/// `\genfrac` with delimiters, which has no direct Typst equivalent.
fn render_delimited(
  content : String,
  left_delim : String?,
  right_delim : String?,
) -> String {
  let l = left_delim.map_or("", render_lr_delim)
  let r = right_delim.map_or("", render_lr_delim)
  if l == "" && r == "" {
    content
  } else {
    "\{content} lr(size: #2em, \{if l == "" { r } else { l }})"
  }
}

///|
fn render_spacing(text : String) -> String {
  match text {
    "\\nobreak" | "\\allowbreak" => ""
    _ => " "
  }
}

///|
fn render_kern(dimension : @katex_parser.Measurement) -> String {
  let unit = dimension.unit
  let amount = if unit == "mu" {
    let em = (dimension.number / 18.0 * 1000.0).round() / 1000.0
    "\{em}em"
  } else if unit == "fill" {
    "1fr"
  } else {
    render_measurement(dimension)
  }
  "#h(\{amount})"
}
