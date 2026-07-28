///|
/// A 2D text block where every line has equal width.
/// Supports vertical stacking, horizontal juxtaposition with vertical
/// centering, and delimiter wrapping — building blocks for block-mode
/// Unicode rendering of matrices, fractions, delimited expressions, etc.
pub(all) struct Block {
  lines : Array[String]
  width : Int
}

///|
pub fn Block::from(s : String) -> Block {
  { lines: [s], width: s.length() }
}

///|
pub fn Block::empty() -> Block {
  { lines: [], width: 0 }
}

///|
pub fn Block::render(self : Block) -> String {
  self.lines.join("\n")
}

///|
pub fn Block::height(self : Block) -> Int {
  self.lines.length()
}

///|
pub fn Block::width(self : Block) -> Int {
  self.width
}

///|
pub fn Block::pad_to(self : Block, target_width : Int) -> Block {
  guard target_width > self.width else { self }
  let lines = self.lines.map(l => pad_right(l, target_width))
  { lines, width: target_width }
}

///|
pub fn Block::center(self : Block, target_width : Int) -> Block {
  guard self.lines.length() > 0 && target_width > self.width else { self }
  let lines = self.lines.map(l => center_text(l, target_width))
  { lines, width: target_width }
}

///|
/// Vertical concatenation. The narrower block is padded to match width.
pub fn Block::above(self : Block, other : Block) -> Block {
  let new_w = self.width.max(other.width)
  let self_lines = self.lines.map(l => pad_right(l, new_w))
  let other_lines = other.lines.map(l => pad_right(l, new_w))
  { lines: self_lines + other_lines, width: new_w }
}

///|
/// Horizontal concatenation, vertically centering the shorter block.
pub fn Block::beside(self : Block, other : Block) -> Block {
  let new_h = self.lines.length().max(other.lines.length())
  let self_padded = vpad(self, new_h)
  let other_padded = vpad(other, new_h)
  let new_w = self.width + other.width
  let lines = Array::makei(new_h, i => self_padded[i] + other_padded[i])
  { lines, width: new_w }
}

///|
pub fn Block::append_left(self : Block, label : Block) -> Block {
  label.beside(self)
}

///|
pub fn Block::append_right(self : Block, label : Block) -> Block {
  self.beside(label)
}

///|
/// Enclose every line with `left` and `right` delimiters.
pub fn Block::enclose(self : Block, left : String, right : String) -> Block {
  guard self.lines.length() > 0 else { Block::from("\{left}\{right}") }
  let lines = self.lines.map(l => "\{left}\{l}\{right}")
  { lines, width: self.width + left.length() + right.length() }
}

///|
/// Build a single-row block from cell text strings, each padded to the
/// corresponding column width, then joined by `gap`.
pub fn Block::row(cells : Array[String], widths : Array[Int], gap : String) -> Block {
  Block::from(
    Array::makei(cells.length(), j => pad_right(cells[j], widths[j])).join(gap),
  )
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

///|
pub fn pad_right(s : String, width : Int) -> String {
  let need = width - s.length()
  guard need > 0 else { s }
  s + " ".repeat(need)
}

///|
/// Compute the maximum width per column across all rows of cell strings.
pub fn column_widths(cells : Array[Array[String]]) -> Array[Int] {
  let max_cols = cells.fold(init=0, fn(m, row) {
    let len = row.length()
    if len > m {
      len
    } else {
      m
    }
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
fn center_text(s : String, width : Int) -> String {
  let need = width - s.length()
  guard need > 0 else { s }
  let left = need / 2
  let right = need - left
  " ".repeat(left) + s + " ".repeat(right)
}

///|
/// Vertically pad a block so it has exactly `target` rows. Extra rows are
/// filled with blank (space-only) lines, evenly distributed above and below.
fn vpad(b : Block, target : Int) -> Array[String] {
  guard b.lines.length() < target else { b.lines }
  let total_pad = target - b.lines.length()
  let top_pad = total_pad / 2
  let bottom_pad = total_pad - top_pad
  let empty = " ".repeat(b.width)
  let top = Array::make(top_pad, empty)
  let bottom = Array::make(bottom_pad, empty)
  top + b.lines + bottom
}
