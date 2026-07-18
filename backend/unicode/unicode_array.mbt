///|
fn render_array_inline(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  body.map(r => render_row(r, state)).join("; ")
}

///|
fn render_array_block(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  let rows = render_array_rows(body, state)
  rows.join("\n")
}

///|
fn render_array_rows(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> Array[String] {
  let cell_texts = body.map(
    r => r.map(c => render_node_internal(c, state)),
  )
  let widths = column_widths(cell_texts)
  cell_texts.map(row => {
    Array::makei(row.length(), j => pad_right(row[j], widths[j])).join("  ")
  })
}

///|
fn render_leftright_block(
  left : String,
  right : String,
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  let rows = render_array_rows(body, state)
  rows.map(row => left + row + right).join("\n")
}

///|
fn column_widths(cells : Array[Array[String]]) -> Array[Int] {
  let max_cols = cells.fold(
    init=0,
    fn(m, row) {
      let len = row.length()
      if len > m { len } else { m }
    },
  )
  let widths = Array::make(max_cols, 0)
  for row in cells {
    for j, cell in row {
      let w = cell.length()
      if w > widths[j] {
        widths[j] = w
      }
    }
  }
  widths
}

///|
fn pad_right(s : String, width : Int) -> String {
  let need = width - s.length()
  if need <= 0 {
    return s
  }
  s + ' '.repeat(need)
}

///|
fn render_row(
  row : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> String {
  row.map(c => render_node_internal(c, state)).join(", ")
}
