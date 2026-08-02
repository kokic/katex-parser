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
  columns : Array[@katex_parser.ArrayColumn]?,
  hlines_before_row : Array[Array[Bool]],
  state : RenderState,
) -> String {
  cell_block(body, columns, hlines_before_row, state).render()
}

///|
fn render_leftright_block(
  left : String,
  right : String,
  body : Array[Array[@katex_parser.ParseNode]],
  columns : Array[@katex_parser.ArrayColumn]?,
  hlines_before_row : Array[Array[Bool]],
  state : RenderState,
) -> Block {
  cell_block(body, columns, hlines_before_row, state).enclose(left, right)
}

///|
/// Renders an array as a block, drawing vertical separators from the column
/// spec (`|`, `:`) and horizontal rules from `\hline`/`\hdashline`. Trailing
/// empty rows (produced by a final `\\`) are dropped, with their rules kept
/// as a bottom border.
fn cell_block(
  body : Array[Array[@katex_parser.ParseNode]],
  columns : Array[@katex_parser.ArrayColumn]?,
  hlines_before_row : Array[Array[Bool]],
  state : RenderState,
) -> Block {
  let cell_texts = body.map(r => r.map(c => render_node_internal(c, state)))
  let n = cell_texts.length()
  let mut last = n - 1
  while last >= 0 && cell_texts[last].all(s => s == "") {
    last = last - 1
  }
  guard last >= 0 else { return Block::empty() }
  let rows = Array::makei(last + 1, i => cell_texts[i])
  let widths = column_widths(rows)
  let ncols = widths.length()
  guard ncols > 0 else { return Block::empty() }
  let vlines = separator_glyphs(columns, ncols, state.config.line_style)
  let (line_width, vbar_pos) = row_geometry(widths, vlines)
  let hline_kind = hline_band_kinds(hlines_before_row, last)
  let lines = render_array_lines(
    rows,
    hlines_before_row,
    widths,
    vlines,
    vbar_pos,
    line_width,
    hline_kind,
    state.config.line_style,
    last,
  )
  let block = Block::from(lines.join("\n"))
  // Math axis sits at the vertical center of the array, so surrounding
  // content (e.g. `=` in `x = \begin{cases}...`) aligns against it.
  { ..block, baseline: block.height() / 2 }
}

///|
/// Renders every row (with the rules preceding it) plus the trailing rules
/// into a list of lines. `hlines_before_row[i]` holds the rules before row
/// `i`; entries after the last kept row are drawn as a bottom border.
fn render_array_lines(
  rows : Array[Array[String]],
  hlines_before_row : Array[Array[Bool]],
  widths : Array[Int],
  vlines : Array[String?],
  vbar_pos : Array[Int?],
  line_width : Int,
  hline_kind : Array[Array[Int]],
  style : LineStyle,
  last : Int,
) -> Array[String] {
  let lines : Array[String] = []
  for k in 0..<=last {
    for band, dashed in hlines_before_row.get(k).unwrap_or([]) {
      lines.push(
        hline_rule(
          line_width,
          vbar_pos,
          style,
          dashed,
          band_of(hline_kind, k, band),
        ),
      )
    }
    lines.push(row_line(rows[k], widths, vlines))
  }
  for k in (last + 1)..<hlines_before_row.length() {
    for band, dashed in hlines_before_row.get(k).unwrap_or([]) {
      lines.push(
        hline_rule(
          line_width,
          vbar_pos,
          style,
          dashed,
          band_of(hline_kind, k, band),
        ),
      )
    }
  }
  lines
}

///|
/// For each `hlines_before_row` entry, records the border kind (top, middle,
/// or bottom) of every rule it contains. Rules before the first row are the
/// top border, rules before a middle row are middle rules, and rules after
/// the last kept row are the bottom border.
fn hline_band_kinds(
  hlines_before_row : Array[Array[Bool]],
  last : Int,
) -> Array[Array[Int]] {
  let kinds : Array[Array[Int]] = []
  for k in 0..<hlines_before_row.length() {
    let kind = if k == 0 { 0 } else if k <= last { 1 } else { 2 }
    kinds.push(hlines_before_row.get(k).unwrap_or([]).map(_ => kind))
  }
  kinds
}

///|
fn band_of(kinds : Array[Array[Int]], k : Int, band : Int) -> Int {
  match kinds.get(k) {
    Some(arr) => arr.get(band).unwrap_or(1)
    None => 1
  }
}

///|
/// A row line of padded cells joined by inter-column gaps, with vertical
/// separator glyphs inserted at the corresponding boundaries.
fn row_line(
  cells : Array[String],
  widths : Array[Int],
  vlines : Array[String?],
) -> String {
  let mut result = ""
  match vlines[0] {
    Some(v) => result = result + v
    None => ()
  }
  for j in 0..<widths.length() {
    result = result + pad_right(cells.get(j).unwrap_or(""), widths[j])
    if j < widths.length() - 1 {
      result = result + boundary_gap(vlines[j + 1])
    } else {
      match vlines[widths.length()] {
        Some(v) => result = result + v
        None => ()
      }
    }
  }
  result
}

///|
/// The text between two adjacent columns: two spaces, or one space around a
/// vertical separator when the boundary has one.
fn boundary_gap(vline : String?) -> String {
  match vline {
    Some(v) => " \{v} "
    None => "  "
  }
}

///|
/// Computes the total display width of a row and the character position of
/// every vertical separator within it.
fn row_geometry(
  widths : Array[Int],
  vlines : Array[String?],
) -> (Int, Array[Int?]) {
  let n = widths.length()
  let vbar_pos : Array[Int?] = Array::make(n + 1, None)
  let mut cursor = 0
  match vlines[0] {
    Some(_) => {
      vbar_pos[0] = Some(0)
      cursor = 1
    }
    None => ()
  }
  for j in 0..<n {
    cursor = cursor + widths[j]
    if j < n - 1 {
      match vlines[j + 1] {
        Some(_) => {
          vbar_pos[j + 1] = Some(cursor + 1)
          cursor = cursor + 3
        }
        None => cursor = cursor + 2
      }
    } else {
      match vlines[n] {
        Some(_) => {
          vbar_pos[n] = Some(cursor)
          cursor = cursor + 1
        }
        None => ()
      }
    }
  }
  (cursor, vbar_pos)
}

///|
/// Extracts one vertical-separator glyph per boundary (before, between, and
/// after every column) from the array column spec.
fn separator_glyphs(
  columns : Array[@katex_parser.ArrayColumn]?,
  ncols : Int,
  style : LineStyle,
) -> Array[String?] {
  let result : Array[String?] = Array::make(ncols + 1, None)
  guard columns is Some(cols) else { return result }
  let mut boundary = 0
  for col in cols {
    match col {
      @katex_parser.ArrayColumn::AlignColumn(..) => boundary = boundary + 1
      @katex_parser.ArrayColumn::SeparatorColumn(separator~) =>
        if boundary <= ncols {
          result[boundary] = Some(array_vbar(style, separator == ":"))
        }
    }
  }
  result
}

///|
fn array_vbar(style : LineStyle, dashed : Bool) -> String {
  match style {
    Ascii => if dashed { ":" } else { "|" }
    Unicode => if dashed { "┊" } else { "│" }
  }
}

///|
/// A horizontal rule line spanning the array width, with tee/corner glyphs at
/// the vertical separator positions.
fn hline_rule(
  width : Int,
  vbar_pos : Array[Int?],
  style : LineStyle,
  dashed : Bool,
  kind : Int,
) -> String {
  let hbar = match style {
    Ascii => "-"
    Unicode => if dashed { "┄" } else { "─" }
  }
  let left_pos = vbar_pos[0]
  let right_pos = vbar_pos[vbar_pos.length() - 1]
  let mut result = ""
  for i in 0..<width {
    let junction = if is_vbar_position(vbar_pos, i) {
      hline_junction(style, kind, left_pos, right_pos, i)
    } else {
      hbar
    }
    result = result + junction
  }
  result
}

///|
fn is_vbar_position(vbar_pos : Array[Int?], i : Int) -> Bool {
  let mut found = false
  for pos in vbar_pos {
    match pos {
      Some(p) if p == i => found = true
      _ => ()
    }
  }
  found
}

///|
/// The glyph where a horizontal rule meets a vertical separator: corners at
/// the outer edges, tees elsewhere. Border kind: 0 = top, 1 = middle,
/// 2 = bottom.
fn hline_junction(
  style : LineStyle,
  kind : Int,
  left_pos : Int?,
  right_pos : Int?,
  i : Int,
) -> String {
  match style {
    Ascii => "+"
    Unicode =>
      match kind {
        0 =>
          if left_pos is Some(p) && p == i {
            "┌"
          } else if right_pos is Some(p) && p == i {
            "┐"
          } else {
            "┬"
          }
        2 =>
          if left_pos is Some(p) && p == i {
            "└"
          } else if right_pos is Some(p) && p == i {
            "┘"
          } else {
            "┴"
          }
        _ =>
          if left_pos is Some(p) && p == i {
            "├"
          } else if right_pos is Some(p) && p == i {
            "┤"
          } else {
            "┼"
          }
      }
  }
}
