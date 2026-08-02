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
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> Block {
  let grid = body.map(row => row.map(c => classify_cd_cell(c, state)))
  guard grid.length() > 0 && grid[0].length() > 0 else { return Block::empty() }
  let n_nodes = grid[0].length() / 2 + 1
  let hbar = line_style_frac_bar(state.config.line_style)
  let vbar = cd_vbar(state.config.line_style)
  let (node_w, arrow_w) = cd_column_widths(grid, n_nodes, vbar)
  let bands : Array[Block] = []
  for row_index, row in grid {
    if row_index % 2 == 0 {
      bands.push(cd_node_row_block(row, node_w, arrow_w, hbar))
    } else {
      bands.push(cd_varrow_row_block(row, node_w, arrow_w, vbar))
    }
  }
  let mut result = Block::empty()
  for band in bands {
    if result.height() == 0 {
      result = band
    } else {
      result = result.above(band)
    }
  }
  { ..result, baseline: result.height() / 2 }
}

///|
fn classify_cd_cell(
  cell : @katex_parser.ParseNode,
  state : RenderState,
) -> CdCell {
  match cell {
    @katex_parser.ParseNode::Styling(body=[inner], ..) => classify_cd_inner(inner, cell, state)
    @katex_parser.ParseNode::Styling(body=[], ..) => CdEmpty
    _ => CdNode(render_node_internal(cell, state))
  }
}

///|
fn classify_cd_inner(
  inner : @katex_parser.ParseNode,
  cell : @katex_parser.ParseNode,
  state : RenderState,
) -> CdCell {
  match inner {
    @katex_parser.ParseNode::XArrow(label~, body~, below~, ..) =>
      match cd_arrow_dir(label) {
        Some(dir) =>
          CdHArrow(
            dir,
            render_node_internal(body, state),
            below.map_or("", fn(b) { render_node_internal(b, state) }),
          )
        None => CdNode(render_node_internal(cell, state))
      }
    @katex_parser.ParseNode::CdParent(fragment~, ..) => classify_cd_parent(fragment, cell, state)
    _ => CdNode(render_node_internal(cell, state))
  }
}

///|
fn classify_cd_parent(
  fragment : @katex_parser.ParseNode,
  cell : @katex_parser.ParseNode,
  state : RenderState,
) -> CdCell {
  match fragment {
    @katex_parser.ParseNode::OrdGroup(body~, ..) => {
      let mut left = ""
      let mut right = ""
      let mut dir = "V"
      for node in body {
        match node {
          @katex_parser.ParseNode::CdLabel(side="left", label=l, ..) =>
            left = render_node_internal(l, state)
          @katex_parser.ParseNode::CdLabel(side="right", label=r, ..) =>
            right = render_node_internal(r, state)
          @katex_parser.ParseNode::DelimSizing(delim~, ..) =>
            if delim == "\\uparrow" {
              dir = "A"
            }
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
    ">" => hbar.repeat(w - 1) + "→"
    "<" => "←" + hbar.repeat(w - 1)
    _ => "=".repeat(w)
  }
}

///|
fn cd_varrow_lines(
  dir : String,
  left : String,
  right : String,
  vbar : String,
) -> Array[String] {
  let pad = " ".repeat(left.length())
  match dir {
    "V" => [pad + vbar, left + vbar + right, pad + "↓"]
    "A" => [pad + "↑", left + vbar + right, pad + vbar]
    _ => [pad + vbar, left + vbar + right, pad + vbar]
  }
}

///|
fn cd_column_widths(
  grid : Array[Array[CdCell]],
  n_nodes : Int,
  vbar : String,
) -> (Array[Int], Array[Int]) {
  let node_w = Array::make(n_nodes, 0)
  let arrow_w = Array::make(n_nodes - 1, 4)
  for row_index, row in grid {
    if row_index % 2 == 0 {
      for col, cell in row {
        if col % 2 == 0 {
          match cell {
            CdNode(text) => node_w[col / 2] = node_w[col / 2].max(text.length())
            _ => ()
          }
        } else {
          match cell {
            CdHArrow(_, upper, lower) =>
              arrow_w[col / 2] = arrow_w[col / 2].max(upper.length()).max(lower.length())
            CdNode(text) => arrow_w[col / 2] = arrow_w[col / 2].max(text.length())
            _ => ()
          }
        }
      }
    } else {
      for col, cell in row {
        if col % 2 == 0 {
          match cell {
            CdVArrow(dir, left, right) =>
              for line in cd_varrow_lines(dir, left, right, vbar) {
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
fn cd_node_row_block(
  row : Array[CdCell],
  node_w : Array[Int],
  arrow_w : Array[Int],
  hbar : String,
) -> Block {
  let n = row.length()
  let main : Array[String] = Array::make(n, "")
  for col, cell in row {
    if col % 2 == 0 {
      main[col] = match cell {
        CdNode(text) => text
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
  let mut lines = [cd_pad_line(main, node_w, arrow_w)]
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
    lines = [cd_pad_line(cells, node_w, arrow_w)] + lines
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
    lines.push(cd_pad_line(cells, node_w, arrow_w))
  }
  Block::from(lines.join("\n"))
}

///|
fn cd_row_has_upper(row : Array[CdCell]) -> Bool {
  for cell in row {
    match cell {
      CdHArrow(_, upper, _) if upper.length() > 0 => return true
      _ => ()
    }
  }
  false
}

///|
fn cd_row_has_lower(row : Array[CdCell]) -> Bool {
  for cell in row {
    match cell {
      CdHArrow(_, _, lower) if lower.length() > 0 => return true
      _ => ()
    }
  }
  false
}

///|
fn cd_varrow_row_block(
  row : Array[CdCell],
  node_w : Array[Int],
  arrow_w : Array[Int],
  vbar : String,
) -> Block {
  let n = row.length()
  let lines : Array[String] = []
  for h in 0..<3 {
    let cells : Array[String] = Array::make(n, "")
    for col, cell in row {
      if col % 2 == 0 {
        cells[col] = match cell {
          CdVArrow(dir, left, right) => cd_varrow_lines(dir, left, right, vbar)[h]
          _ => ""
        }
      }
    }
    lines.push(cd_pad_line(cells, node_w, arrow_w))
  }
  Block::from(lines.join("\n"))
}

///|
fn cd_pad_line(
  cells : Array[String],
  node_w : Array[Int],
  arrow_w : Array[Int],
) -> String {
  let parts = Array::makei(cells.length(), j =>
    if j % 2 == 0 {
      pad_right(cells[j], node_w[j / 2])
    } else {
      pad_right(cells[j], arrow_w[j / 2])
    }
  )
  parts.join(" ")
}
