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

///|
fn render_array_block(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  cell_block(body, state).render()
}

///|
fn render_leftright_block(
  left : String,
  right : String,
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  cell_block(body, state).enclose(left, right).render()
}

///|
fn cell_block(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> Block {
  let cell_texts = body.map(r => r.map(c => render_node_internal(c, state)))
  let widths = column_widths(cell_texts)
  let rows = cell_texts.map(cell_row => Block::row(cell_row, widths, "  "))
  rows.fold(init=Block::empty(), (acc, row) => {
    guard acc.height() > 0 else { row }
    acc.above(row)
  })
}
