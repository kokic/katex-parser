///|
/// Cell classification for commutative-diagram (`CD`) rendering.
priv enum CdCell {
  CdEmpty
  CdNode(String)
  CdHArrow(String, String, String)
  CdVArrow(String, String, String)
}

///|
/// Renders a `CD` array as a block commutative diagram. Even rows hold the
/// nodes and horizontal arrows; odd rows hold the vertical arrows connecting
/// them.
fn render_cd_block(
  body : Array[Array[@katex.ParseNode]],
  state : RenderState,
) -> Block {
  let grid = body.map(row => row.map(c => classify_cd_cell(c, state)))
  guard grid.length() > 0 && grid[0].length() > 0 else { return Block::empty() }
  let n_nodes = grid[0].length() / 2 + 1
  let hbar = line_style_frac_bar(state.config.line_style)
  let vbar = cd_vbar(state.config.line_style)
  let (node_w, arrow_w, offsets) = cd_column_widths(grid, n_nodes, vbar)
  let bands : Array[Block] = []
  for row_index, row in grid {
    if row_index % 2 == 0 {
      bands.push(cd_node_row_block(row, node_w, arrow_w, offsets, hbar))
    } else {
      bands.push(cd_varrow_row_block(row, node_w, arrow_w, offsets, vbar))
    }
  }
  let result = bands.fold(init=Block::empty(), (acc, band) => {
    guard acc.height() > 0 else { band }
    acc.above(band)
  })
  { ..result, baseline: result.height() / 2, }
}

///|
fn classify_cd_cell(cell : @katex.ParseNode, state : RenderState) -> CdCell {
  match cell {
    @katex.ParseNode::Styling(body=[inner], ..) =>
      classify_cd_inner(inner, cell, state)
    @katex.ParseNode::Styling(body=[], ..) => CdEmpty
    _ => CdNode(render_node_internal(cell, state))
  }
}

///|
fn classify_cd_inner(
  inner : @katex.ParseNode,
  cell : @katex.ParseNode,
  state : RenderState,
) -> CdCell {
  match inner {
    @katex.ParseNode::XArrow(label~, body~, below~, ..) if cd_arrow_dir(label)
      is Some(dir) =>
      CdHArrow(
        dir,
        render_node_internal(body, state),
        below.map_or("", b => render_node_internal(b, state)),
      )
    @katex.ParseNode::CdParent(fragment~, ..) =>
      classify_cd_parent(fragment, cell, state)
    _ => CdNode(render_node_internal(cell, state))
  }
}

///|
fn classify_cd_parent(
  fragment : @katex.ParseNode,
  cell : @katex.ParseNode,
  state : RenderState,
) -> CdCell {
  match fragment {
    @katex.ParseNode::OrdGroup(body~, ..) => {
      let mut left = ""
      let mut right = ""
      let mut dir = "V"
      for node in body {
        match node {
          @katex.ParseNode::CdLabel(side="left", label=l, ..) =>
            left = render_node_internal(l, state)
          @katex.ParseNode::CdLabel(side="right", label=r, ..) =>
            right = render_node_internal(r, state)
          @katex.ParseNode::DelimSizing(delim~, ..) if delim == "\\uparrow" =>
            dir = "A"
          _ => ()
        }
      }
      CdVArrow(dir, left, right)
    }
    _ => CdNode(render_node_internal(cell, state))
  }
}

///|
fn cd_arrow_dir(label : String) -> String? {
  match label {
    "\\\\cdrightarrow" => Some(">")
    "\\\\cdleftarrow" => Some("<")
    "\\\\cdlongequal" => Some("=")
    _ => None
  }
}

///|
fn cd_vbar(style : LineStyle) -> String {
  match style {
    Ascii => "|"
    Unicode => "│"
  }
}

///|
fn cd_harrow_line(dir : String, w : Int, hbar : String) -> String {
  match dir {
    ">" => "\{hbar.repeat(w - 1)}→"
    "<" => "←\{hbar.repeat(w - 1)}"
    _ => "=".repeat(w)
  }
}

///|
fn cd_varrow_lines(
  dir : String,
  left : String,
  right : String,
  vbar : String,
  offset : Int,
) -> Array[String] {
  let pad = " ".repeat(offset)
  let labels = pad_right(left, offset) + vbar + right
  match dir {
    "V" => [pad + vbar, labels, "\{pad}↓"]
    "A" => ["\{pad}↑", labels, pad + vbar]
    _ => [pad + vbar, labels, pad + vbar]
  }
}

///|
/// Computes the CD layout geometry: node column widths, arrow column widths,
/// and the shaft offset of every node column (the max left-label width of its
/// vertical arrows).
///
/// Layout: columns alternate node/arrow (even/odd). A node column's shaft
/// offset shifts all its content right so v-arrow labels line up, which also
/// shifts the target node of a left-adjacent arrow; the arrow widths are
/// therefore extended by the target column's offset at the end.
fn cd_column_widths(
  grid : Array[Array[CdCell]],
  n_nodes : Int,
  vbar : String,
) -> (Array[Int], Array[Int], Array[Int]) {
  let offsets = cd_shaft_offsets(grid, n_nodes)
  let (node_w, arrow_w) = cd_cell_widths(grid, n_nodes, offsets, vbar)
  let arrow_w = Array::makei(arrow_w.length(), k => arrow_w[k] + offsets[k + 1])
  (node_w, arrow_w, offsets)
}

///|
/// Pass 1: the shaft offset of each node column, i.e. the widest left label
/// among the vertical arrows in that column.
fn cd_shaft_offsets(grid : Array[Array[CdCell]], n_nodes : Int) -> Array[Int] {
  let offsets = Array::make(n_nodes, 0)
  for row_index, row in grid {
    guard row_index % 2 == 1 else { continue }
    for col, cell in row {
      guard col % 2 == 0 else { continue }
      match cell {
        CdVArrow(_, left, _) =>
          offsets[col / 2] = offsets[col / 2].max(left.length())
        _ => ()
      }
    }
  }
  offsets
}

///|
/// Pass 2: node widths from node text (shifted by the shaft offset) and
/// v-arrow lines; arrow widths from h-arrow labels and cell node text.
fn cd_cell_widths(
  grid : Array[Array[CdCell]],
  n_nodes : Int,
  offsets : Array[Int],
  vbar : String,
) -> (Array[Int], Array[Int]) {
  let node_w = Array::make(n_nodes, 0)
  let arrow_w = Array::make(n_nodes - 1, 4)
  for row_index, row in grid {
    if row_index % 2 == 0 {
      for col, cell in row {
        if col % 2 == 0 {
          match cell {
            CdNode(text) =>
              node_w[col / 2] = node_w[col / 2].max(
                offsets[col / 2] + text.length(),
              )
            _ => ()
          }
        } else {
          match cell {
            CdHArrow(_, upper, lower) =>
              arrow_w[col / 2] = arrow_w[col / 2]
                .max(upper.length())
                .max(lower.length())
            CdNode(text) =>
              arrow_w[col / 2] = arrow_w[col / 2].max(text.length())
            _ => ()
          }
        }
      }
    } else {
      for col, cell in row {
        if col % 2 == 0 {
          match cell {
            CdVArrow(dir, left, right) =>
              for
                line in cd_varrow_lines(
                  dir,
                  left,
                  right,
                  vbar,
                  offsets[col / 2],
                ) {
                node_w[col / 2] = node_w[col / 2].max(line.length())
              }
            _ => ()
          }
        }
      }
    }
  }
  (node_w, arrow_w)
}

///|
/// Renders one node row (even grid rows) as a band: the main line holds the
/// nodes and horizontal arrow shafts; label lines are prepended/appended when
/// any arrow carries an upper/lower label.
fn cd_node_row_block(
  row : Array[CdCell],
  node_w : Array[Int],
  arrow_w : Array[Int],
  offsets : Array[Int],
  hbar : String,
) -> Block {
  let n = row.length()
  let main : Array[String] = Array::make(n, "")
  for col, cell in row {
    if col % 2 == 0 {
      main[col] = match cell {
        CdNode(text) => " ".repeat(offsets[col / 2]) + text
        _ => ""
      }
    } else {
      main[col] = match cell {
        CdHArrow(dir, _, _) => cd_harrow_line(dir, arrow_w[col / 2], hbar)
        CdNode(text) => text
        _ => ""
      }
    }
  }
  let mut lines = [cd_pad_line(main, node_w, arrow_w, offsets)]
  if cd_row_has_upper(row) {
    let cells : Array[String] = Array::make(n, "")
    for col, cell in row {
      if col % 2 == 1 {
        cells[col] = match cell {
          CdHArrow(_, upper, _) => center_text(upper, arrow_w[col / 2])
          _ => ""
        }
      }
    }
    lines = [cd_pad_line(cells, node_w, arrow_w, offsets)] + lines
  }
  if cd_row_has_lower(row) {
    let cells : Array[String] = Array::make(n, "")
    for col, cell in row {
      if col % 2 == 1 {
        cells[col] = match cell {
          CdHArrow(_, _, lower) => center_text(lower, arrow_w[col / 2])
          _ => ""
        }
      }
    }
    lines.push(cd_pad_line(cells, node_w, arrow_w, offsets))
  }
  Block::from(lines.join("\n"))
}

///|
fn cd_row_has_upper(row : Array[CdCell]) -> Bool {
  row.any(cell => {
    match cell {
      CdHArrow(_, upper, _) => upper.length() > 0
      _ => false
    }
  })
}

///|
fn cd_row_has_lower(row : Array[CdCell]) -> Bool {
  row.any(cell => {
    match cell {
      CdHArrow(_, _, lower) => lower.length() > 0
      _ => false
    }
  })
}

///|
fn cd_varrow_row_block(
  row : Array[CdCell],
  node_w : Array[Int],
  arrow_w : Array[Int],
  offsets : Array[Int],
  vbar : String,
) -> Block {
  let n = row.length()
  let lines : Array[String] = []
  for h in 0..<3 {
    let cells : Array[String] = Array::make(n, "")
    for col, cell in row {
      if col % 2 == 0 {
        cells[col] = match cell {
          CdVArrow(dir, left, right) =>
            cd_varrow_lines(dir, left, right, vbar, offsets[col / 2])[h]
          _ => ""
        }
      }
    }
    lines.push(cd_pad_line(cells, node_w, arrow_w, offsets))
  }
  Block::from(lines.join("\n"))
}

///|
fn cd_pad_line(
  cells : Array[String],
  node_w : Array[Int],
  arrow_w : Array[Int],
  offsets : Array[Int],
) -> String {
  let mut result = ""
  for j = 0; j < cells.length(); j = j + 1 {
    if j % 2 == 0 {
      result = result + pad_right(cells[j], node_w[j / 2])
      if j + 1 < cells.length() {
        result = result + " "
      }
    } else {
      result = result + pad_right(cells[j], arrow_w[j / 2])
      // The target node is shifted right by its column's shaft offset, so
      // shrink this gap by that offset to keep a single space before it.
      let next_node = j / 2 + 1
      if next_node < offsets.length() {
        result = result + " ".repeat((1 - offsets[next_node]).max(0))
      }
    }
  }
  result
}
