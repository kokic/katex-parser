///|
fn render_styling(
  body : Array[@katex.ParseNode],
  style : @katex.StyleLevel,
  parent : RenderState,
) -> String {
  let content = render_nodes(body, RenderState::at(style))
  guard style != parent.typst && content != "" else { return content }
  let name = match style {
    DisplayStyle => "display"
    TextStyle => "inline"
    ScriptStyle => "script"
    ScriptScriptStyle => "sscript"
  }
  math_fn(name, content)
}

///|
fn script_style(style : @katex.StyleLevel) -> @katex.StyleLevel {
  match style {
    DisplayStyle | TextStyle => ScriptStyle
    ScriptStyle | ScriptScriptStyle => ScriptScriptStyle
  }
}

///|
fn RenderState::script(self : RenderState) -> RenderState {
  { tex: script_style(self.tex), typst: script_style(self.typst), }
}

///|
fn reduced_style(style : @katex.StyleLevel) -> @katex.StyleLevel {
  if style is DisplayStyle {
    TextStyle
  } else {
    script_style(style)
  }
}

///|
fn RenderState::reduced(self : RenderState) -> RenderState {
  { tex: reduced_style(self.tex), typst: reduced_style(self.typst), }
}

///|
fn render_sizing(
  size : Int32,
  body : Array[@katex.ParseNode],
  state : RenderState,
) -> String {
  let em = @backend.katex_size_multiplier(size)
  "text(size: #\{em}em, \{render_nodes(body, state)})"
}

///|
fn render_sup_sub(
  base : @katex.ParseNode?,
  sup : @katex.ParseNode?,
  sub : @katex.ParseNode?,
  state : RenderState,
) -> String {
  guard base is Some(node) else { return with_scripts("zws", sup, sub, state) }
  match node {
    @katex.ParseNode::HorizBrace(label~, base=brace_base, ..) =>
      render_folded_brace(label, brace_base, sup, sub, state)
    @katex.ParseNode::XArrow(label~, body~, below~, ..) =>
      render_folded_arrow(label, body, below, sup, sub, state)
    // `\dddot`/`\ddddot` expand to
    // `\overset{\raisebox{-0.1ex}{\normalsize ...}}{x}`; recognize that
    // shape and emit the native dot accents instead of the generic
    // `attach` fallback.
    @katex.ParseNode::Op(
      content=@katex.OperatorContent::BodyOperator(body),
      limits=true,
      ..
    ) if sup.map_or(None, dddot_dots) is Some(count) =>
      "accent(\{wrap_arg(render_nodes(body, state))}, \{dddot_symbol(count)})"
    @katex.ParseNode::Op(
      content=@katex.OperatorContent::BodyOperator(_),
      limits=true,
      ..
    ) => render_sup_attach(node, sup, sub, state)
    @katex.ParseNode::OperatorName(limits=true, ..) =>
      render_sup_attach(node, sup, sub, state)
    _ => {
      let base = render_node(node, state)
      // A postfix script binds to the last atom of an infix fraction or
      // flattened group. `attach` takes the whole base without visible parens.
      if contains_script_separator(base) {
        "attach(\{wrap_arg(base)}\{attach_arg("t", sup, state)}\{attach_arg("b", sub, state)})"
      } else {
        with_scripts(base, sup, sub, state)
      }
    }
  }
}

///|
/// `\overset`/`\underset`/`\operatorname*` attach their scripts as limits
/// above/below the operator. `limits(...)` is required: a plain `attach`
/// would only place the scripts next to the base without limit placement.
fn render_sup_attach(
  base : @katex.ParseNode,
  sup : @katex.ParseNode?,
  sub : @katex.ParseNode?,
  state : RenderState,
) -> String {
  with_scripts("limits(\{render_node(base, state)})", sup, sub, state)
}

///|
fn with_scripts(
  base : String,
  sup : @katex.ParseNode?,
  sub : @katex.ParseNode?,
  state : RenderState,
) -> String {
  "\{base}\{script_marks('^', sup, state)}\{script_marks('_', sub, state)}"
}

///|
/// Renders a `^`/`_` script marker with its content, wrapping the content in
/// parentheses when it needs grouping (see `wrap_script`).
fn script_marks(
  mark : Char,
  node : @katex.ParseNode?,
  state : RenderState,
) -> String {
  node.map_or("", node => {
    "\{mark}\{wrap_script(render_node(node, state.script()))}"
  })
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
  contains_top_level_char(text, is_script_separator)
}

///|
fn is_script_separator(c : Char) -> Bool {
  c == ' ' ||
  c == '=' ||
  c == ',' ||
  c == ';' ||
  c == ':' ||
  c == '^' ||
  c == '_'
}

///|
/// `\overbrace{x}^{label}` folds into `attach(overbrace(x), t: label)` since
/// Typst attaches the label relative to the brace.
fn render_folded_brace(
  label : String,
  body : @katex.ParseNode,
  sup : @katex.ParseNode?,
  sub : @katex.ParseNode?,
  state : RenderState,
) -> String {
  let brace = horiz_brace_name(label)
  "attach(\{brace}(\{wrap_arg(render_node(body, state))})\{attach_arg("t", sup, state)}\{attach_arg("b", sub, state)})"
}

///|
/// Renders an `attach(...)` named argument (`, t: ...` / `, b: ...`) when the
/// node is present, or nothing.
fn attach_arg(
  name : String,
  node : @katex.ParseNode?,
  state : RenderState,
) -> String {
  node.map_or("", node => {
    ", \{name}: \{wrap_arg(render_node(node, state.script()))}"
  })
}

///|
fn render_folded_arrow(
  label : String,
  body : @katex.ParseNode,
  below : @katex.ParseNode?,
  sup : @katex.ParseNode?,
  sub : @katex.ParseNode?,
  state : RenderState,
) -> String {
  let arrow = xarrow_name(label)
  let label_state = state.script()
  let body_str = wrap_arg(render_node(body, label_state))
  // A present `sup` takes over the top label; the xarrow's own label moves
  // to `t:`.
  let t_str = sup.map_or(body_str, node => {
    "\{wrap_arg(render_node(node, label_state))}, t: \{body_str}"
  })
  let b_str = {
    guard below is Some(_) else { attach_arg("b", sub, state) }
    attach_arg("b", below, state)
  }
  "attach(\{arrow}, t: \{t_str}\{b_str})"
}

///|
fn render_genfrac(
  numer : @katex.ParseNode,
  denom : @katex.ParseNode,
  has_bar_line : Bool,
  left_delim : String?,
  right_delim : String?,
  state : RenderState,
) -> String {
  let child = state.reduced()
  let num = wrap_frac(render_node(numer, child))
  let den = wrap_frac(render_node(denom, child))
  let frac = "\{num} / \{den}"
  if is_binomial_genfrac(has_bar_line, left_delim, right_delim) {
    "binom(\{num}, \{den})"
  } else if is_delimited_genfrac(has_bar_line, left_delim, right_delim) {
    render_delimited(frac, left_delim, right_delim)
  } else {
    frac
  }
}

///|
/// A `\genfrac` without a bar line and with both delimiters renders as
/// Typst's `binom`.
fn is_binomial_genfrac(
  has_bar_line : Bool,
  left_delim : String?,
  right_delim : String?,
) -> Bool {
  !has_bar_line && left_delim is Some(_) && right_delim is Some(_)
}

///|
/// A `\genfrac` whose delimiters cannot fold into `binom` still needs
/// explicit delimiters around the fraction.
fn is_delimited_genfrac(
  has_bar_line : Bool,
  left_delim : String?,
  right_delim : String?,
) -> Bool {
  (has_bar_line && left_delim is Some(_)) || right_delim is Some(_)
}

///|
/// Typst's `/` is the fraction operator; numerator/denominator containing a
/// top-level `+`/`-`/space (i.e. multiple atoms) need parentheses, since
/// `a + 1 / b` would parse as `a + (1/b)`.
fn wrap_frac(content : String) -> String {
  if contains_top_level_frac_op(content) {
    "(\{content})"
  } else {
    content
  }
}

///|
fn contains_top_level_frac_op(text : String) -> Bool {
  contains_top_level_char(text, is_frac_separator)
}

///|
fn is_frac_separator(c : Char) -> Bool {
  c == ' ' || c == '+' || c == '-' || c == '='
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
  guard l != "" || r != "" else { content }
  lr_single_side(content, l, r)
}

///|
fn render_spacing(text : String) -> String {
  match text {
    "\\nobreak" | "\\allowbreak" => ""
    _ => " "
  }
}

///|
fn render_kern(dimension : @katex.Measurement) -> String {
  let amount = {
    guard @backend.em_value(dimension) is Some(em) && dimension.unit == "mu" else {
      if dimension.unit == "fill" {
        "1fr"
      } else {
        render_measurement(dimension)
      }
    }
    em_string(em)
  }
  "#h(\{amount})"
}
