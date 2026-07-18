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
  let render_display = c => render_node_internal(c, in_display)
  let cell_texts = body.map(r => r.map(render_display))
  let widths = column_widths(cell_texts)
  cell_texts.map(row => {
    let filler = j => pad_right(row[j], widths[j])
    Array::makei(row.length(), filler).join("  ")
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
  let max_cols = cells.fold(init=0, (m, row) => {
    let len = row.length()
    guard len > m else { m }
    len
  })
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
  guard need > 0 else { s }
  s + ' '.repeat(need)
}

///|
fn render_row(
  row : Array[@katex_parser.ParseNode],
  in_display : Bool,
) -> String {
  row.map(c => render_node_internal(c, in_display)).join(", ")
}
