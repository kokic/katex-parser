///|
fn render_array_inline(
  body : Array[Array[@katex.ParseNode]],
  state : RenderState,
) -> String {
  body.map(r => render_row(r, state)).join("; ")
}

///|
fn render_row(row : Array[@katex.ParseNode], state : RenderState) -> String {
  row.map(c => render_node_internal(c, state)).join(", ")
}

///|
fn render_array_block(
  body : Array[Array[@katex.ParseNode]],
  columns : Array[@katex.ArrayColumn]?,
  hlines_before_row : Array[Array[Bool]],
  separation : @katex.ColumnSeparationType?,
  state : RenderState,
) -> String {
  cell_block(body, columns, hlines_before_row, separation, state).render()
}

///|
fn render_leftright_block(
  left : String,
  right : String,
  body : Array[Array[@katex.ParseNode]],
  columns : Array[@katex.ArrayColumn]?,
  hlines_before_row : Array[Array[Bool]],
  separation : @katex.ColumnSeparationType?,
  state : RenderState,
) -> Block {
  cell_block(body, columns, hlines_before_row, separation, state).enclose(
    left, right,
  )
}

///|
/// Renders an array as a block, drawing vertical separators from the column
/// spec (`|`, `:`) and horizontal rules from `\hline`/`\hdashline`. Trailing
/// empty rows (produced by a final `\\`) are dropped, with their rules kept
/// as a bottom border.
///
/// Cells are rendered as `Block`s so multi-line content (e.g. block fractions)
/// contributes its real width and vertical span. Within a row, cell baselines
/// are aligned on a common axis, matching how `beside` composes mixed-height
/// content. Alignment environments (`aligned`/`alignat`/`gather`) honor their
/// column alignment (`r`/`l`/`c`); plain arrays stay left-aligned.
fn cell_block(
  body : Array[Array[@katex.ParseNode]],
  columns : Array[@katex.ArrayColumn]?,
  hlines_before_row : Array[Array[Bool]],
  separation : @katex.ColumnSeparationType?,
  state : RenderState,
) -> Block {
  let cell_blocks = body.map(r => r.map(c => content_block(c, state)))
  let n = cell_blocks.length()
  let mut last = n - 1
  while last >= 0 && cell_blocks[last].all(b => b.lines.length() == 0) {
    last = last - 1
  }
  guard last >= 0 else { return Block::empty() }
  let rows = Array::makei(last + 1, i => cell_blocks[i])
  let widths = column_block_widths(rows)
  let ncols = widths.length()
  guard ncols > 0 else { return Block::empty() }
  let aligns = column_alignments(columns, ncols, separation)
  let vlines = separator_glyphs(columns, ncols, state.config.line_style)
  let (line_width, vbar_pos) = row_geometry(widths, vlines, separation)
  let hline_kind = hline_band_kinds(hlines_before_row, last)
  let lines = render_array_lines(
    rows.map(row => row_block(row, widths, aligns, vlines, separation)),
    hlines_before_row,
    vbar_pos,
    line_width,
    hline_kind,
    state.config.line_style,
    last,
  )
  let block = Block::from(lines.join("\n"))
  let block = pad_gather(block, separation)
  // Math axis sits at the vertical center of the array, so surrounding
  // content (e.g. `=` in `x = \begin{cases}...`) aligns against it.
  { ..block, baseline: block.height() / 2 }
}

///|
/// For `gather`/`gathered`, KaTeX centers each row across the display width.
/// With no viewer width available, approximate the layout by padding the
/// widest row with four spaces on each side and centering the rows in it.
fn pad_gather(
  block : Block,
  separation : @katex.ColumnSeparationType?,
) -> Block {
  guard separation is Some(@katex.ColumnSeparationType::GatherSeparation) else {
    block
  }
  let lines = block.lines.map(l => "    \{l}    ")
  { lines, width: block.width + 8, baseline: block.baseline }
}

///|
/// Computes the display width of every column from the maximum block width in
/// that column across all rows.
fn column_block_widths(rows : Array[Array[Block]]) -> Array[Int] {
  column_max_widths(rows, b => b.width())
}

///|
/// The horizontal alignment of every column. Only alignment environments
/// (`aligned`/`alignat`/`gather`) honor the declared alignment; other arrays
/// keep their cells left-aligned to preserve the existing plain-text look.
fn column_alignments(
  columns : Array[@katex.ArrayColumn]?,
  ncols : Int,
  separation : @katex.ColumnSeparationType?,
) -> Array[String] {
  let parsed : Array[String] = Array::make(ncols, "l")
  guard columns is Some(cols) else { return parsed }
  let mut col = 0
  for spec in cols {
    match spec {
      @katex.ArrayColumn::AlignColumn(alignment~, ..) => {
        if col < ncols {
          parsed[col] = alignment
        }
        col = col + 1
      }
      @katex.ArrayColumn::SeparatorColumn(..) => ()
    }
  }
  match separation {
    Some(@katex.ColumnSeparationType::AlignSeparation)
    | Some(@katex.ColumnSeparationType::AlignAtSeparation)
    | Some(@katex.ColumnSeparationType::GatherSeparation) => parsed
    _ => Array::make(ncols, "l")
  }
}

///|
/// A row of cells padded to their column widths, with every cell's baseline
/// placed on a common axis so that tall cells (block fractions) and short
/// ones line up the way `beside` does. Vertical separators are drawn as
/// full-height bars between the columns.
fn row_block(
  cells : Array[Block],
  widths : Array[Int],
  aligns : Array[String],
  vlines : Array[String?],
  separation : @katex.ColumnSeparationType?,
) -> Block {
  let ncols = widths.length()
  let padded = Array::makei(ncols, j => {
    pad_cell(cells.get(j).unwrap_or(Block::empty()), widths[j], aligns[j])
  })
  let mut row_bl = 0
  for j in 0..<ncols {
    row_bl = row_bl.max(padded[j].baseline)
  }
  let tops : Array[Int] = Array::makei(ncols, j => row_bl - padded[j].baseline)
  let mut row_h = row_bl + 1
  for j in 0..<ncols {
    row_h = row_h.max(tops[j] + padded[j].lines.length())
  }
  let lines : Array[String] = Array::make(row_h, "")
  let mut width = 0
  match vlines[0] {
    Some(v) => {
      for i in 0..<row_h {
        lines[i] = lines[i] + v
      }
      width = width + display_width(v)
    }
    None => ()
  }
  for j in 0..<ncols {
    let cell_lines = vertical_lines(padded[j], tops[j], row_h)
    for i in 0..<row_h {
      lines[i] = lines[i] + cell_lines[i]
    }
    width = width + widths[j]
    if j < ncols - 1 {
      let gap = boundary_gap(vlines, j + 1, separation)
      for i in 0..<row_h {
        lines[i] = lines[i] + gap
      }
      width = width + display_width(gap)
    } else {
      match vlines[ncols] {
        Some(v) => {
          for i in 0..<row_h {
            lines[i] = lines[i] + v
          }
          width = width + display_width(v)
        }
        None => ()
      }
    }
  }
  { lines, width, baseline: row_bl }
}

///|
/// Pads a cell block to a column width according to its alignment. Empty
/// cells grow to the width without any lines.
fn pad_cell(b : Block, width : Int, align : String) -> Block {
  guard b.lines.length() > 0 else { { lines: [], width, baseline: 0 } }
  guard width > b.width else { b }
  match align {
    "r" =>
      {
        lines: b.lines.map(l => " ".repeat(width - display_width(l)) + l),
        width,
        baseline: b.baseline,
      }
    "c" =>
      {
        lines: b.lines.map(l => center_text(l, width)),
        width,
        baseline: b.baseline,
      }
    _ =>
      {
        lines: b.lines.map(l => pad_right(l, width)),
        width,
        baseline: b.baseline,
      }
  }
}

///|
/// Vertically positions a cell's lines inside a row of height `row_h` so its
/// baseline sits on row `top`.
fn vertical_lines(b : Block, top : Int, row_h : Int) -> Array[String] {
  let h = b.lines.length()
  let empty = " ".repeat(b.width)
  let top_lines = Array::make(top, empty)
  let bottom_lines = Array::make((row_h - top - h).max(0), empty)
  top_lines + b.lines + bottom_lines
}

///|
fn column_gap(
  separation : @katex.ColumnSeparationType?,
  boundary : Int,
) -> String {
  match separation {
    Some(@katex.ColumnSeparationType::AlignSeparation) =>
      if boundary % 2 == 0 {
        "  "
      } else {
        ""
      }
    Some(@katex.ColumnSeparationType::AlignAtSeparation)
    | Some(@katex.ColumnSeparationType::GatherSeparation)
    | Some(@katex.ColumnSeparationType::CdSeparation) => ""
    Some(@katex.ColumnSeparationType::SmallSeparation) => "  "
    None => "  "
  }
}

///|
/// The text between two adjacent columns: a one-space gap around a vertical
/// separator when the boundary has one, otherwise the separation-specific
/// inter-column gap.
fn boundary_gap(
  vlines : Array[String?],
  boundary : Int,
  separation : @katex.ColumnSeparationType?,
) -> String {
  match vlines[boundary] {
    Some(v) => " \{v} "
    None => column_gap(separation, boundary)
  }
}

///|
/// Renders every row (with the rules preceding it) plus the trailing rules
/// into a list of lines. `hlines_before_row[i]` holds the rules before row
/// `i`; entries after the last kept row are drawn as a bottom border.
fn render_array_lines(
  row_blocks : Array[Block],
  hlines_before_row : Array[Array[Bool]],
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
    lines.push(row_blocks[k].render())
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
/// Computes the total display width of a row and the character position of
/// every vertical separator within it.
fn row_geometry(
  widths : Array[Int],
  vlines : Array[String?],
  separation : @katex.ColumnSeparationType?,
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
      let gap = boundary_gap(vlines, j + 1, separation)
      match vlines[j + 1] {
        Some(_) => {
          vbar_pos[j + 1] = Some(cursor + 1)
          cursor = cursor + display_width(gap)
        }
        None => cursor = cursor + display_width(gap)
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
  columns : Array[@katex.ArrayColumn]?,
  ncols : Int,
  style : LineStyle,
) -> Array[String?] {
  let result : Array[String?] = Array::make(ncols + 1, None)
  guard columns is Some(cols) else { return result }
  let mut boundary = 0
  for col in cols {
    match col {
      @katex.ArrayColumn::AlignColumn(..) => boundary = boundary + 1
      @katex.ArrayColumn::SeparatorColumn(separator~) =>
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
  vbar_pos.any(pos => pos is Some(p) && p == i)
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
