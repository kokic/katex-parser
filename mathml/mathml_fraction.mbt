///|
fn render_fraction(
  numer : @katex.ParseNode,
  denom : @katex.ParseNode,
  has_bar_line : Bool,
  bar_size : @katex.Measurement?,
  left : String?,
  right : String?,
  state : RenderState,
) -> MathMlNode {
  let attrs = if !has_bar_line {
    [("linethickness", "0px")]
  } else {
    bar_size.map_or([], size => [("linethickness", measurement(size))])
  }
  let child = { ..state, style: @backend.fraction_child_style(state.style), }
  let fraction = element(
    "mfrac",
    children=[render_group(numer, child), render_group(denom, child)],
    attributes=attrs,
  )
  match (left, right) {
    (None, None) => fraction
    _ => {
      let left_children = left.map_or([], delim => [render_fence(delim, None)])
      let right_children = right.map_or([], delim => [render_fence(delim, None)])
      let children = left_children + [fraction] + right_children
      make_row(children)
    }
  }
}
