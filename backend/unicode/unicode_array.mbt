///|
fn render_array_inline(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  body.map(r => render_row(r, state)).join("; ")
}

///|
fn render_row(
  row : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> String {
  row.map(c => render_node_internal(c, state)).join(", ")
}
