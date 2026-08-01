///|
/// A 2D text block where every line has equal width.
/// Supports vertical stacking, horizontal juxtaposition with baseline
/// alignment, and delimiter wrapping — building blocks for block-mode
/// Unicode rendering of matrices, fractions, delimited expressions, etc.
pub(all) struct Block {
  lines : Array[String]
  width : Int
  baseline : Int
}

///|
pub fn Block::from(s : String) -> Block {
  let raw = s.split("\n").to_array()
  let width = raw.fold(init=0, fn(m, l) { m.max(l.length()) })
  let lines = raw.map(fn(l) { pad_right(l.to_owned(), width) })
  { lines, width, baseline: 0 }
}

///|
pub fn Block::empty() -> Block {
  { lines: [], width: 0, baseline: 0 }
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
pub fn Block::baseline(self : Block) -> Int {
  self.baseline
}

///|
pub fn Block::pad_to(self : Block, target_width : Int) -> Block {
  guard target_width > self.width else { self }
  let lines = self.lines.map(l => pad_right(l, target_width))
  { lines, width: target_width, baseline: self.baseline }
}

///|
pub fn Block::center(self : Block, target_width : Int) -> Block {
  guard self.lines.length() > 0 && target_width > self.width else { self }
  let lines = self.lines.map(l => center_text(l, target_width))
  { lines, width: target_width, baseline: self.baseline }
}

///|
/// Vertical concatenation. The narrower block is padded to match width.
pub fn Block::above(self : Block, other : Block) -> Block {
  let new_w = self.width.max(other.width)
  let self_lines = self.lines.map(l => pad_right(l, new_w))
  let other_lines = other.lines.map(l => pad_right(l, new_w))
  // Preserve self's baseline; other's baseline is shifted down by self's height
  { lines: self_lines + other_lines, width: new_w, baseline: self.baseline }
}

///|
/// Horizontal concatenation, aligning blocks at their baseline positions.
pub fn Block::beside(self : Block, other : Block) -> Block {
  let self_h = self.lines.length()
  let other_h = other.lines.length()
  let new_h = self_h.max(other_h)
  let self_bl = self.baseline
  let other_bl = other.baseline
  let diff = (self_bl - other_bl).abs()
  let top_pad_left = if self_bl < other_bl { diff } else { 0 }
  let top_pad_right = if other_bl < self_bl { diff } else { 0 }
  let result_h = new_h.max(self_bl).max(other_bl)
  let self_padded = vpad_at(self, result_h, top_pad_left)
  let other_padded = vpad_at(other, result_h, top_pad_right)
  let new_w = self.width + other.width
  let result_bl = self_bl.max(other_bl)
  let lines = Array::makei(result_h, i => self_padded[i] + other_padded[i])
  { lines, width: new_w, baseline: result_bl }
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
  {
    lines,
    width: self.width + left.length() + right.length(),
    baseline: self.baseline,
  }
}

///|
/// Build a single-row block from cell text strings, each padded to the
/// corresponding column width, then joined by `gap`.
pub fn Block::row(
  cells : Array[String],
  widths : Array[Int],
  gap : String,
) -> Block {
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
/// Vertically pad a block so it has exactly `target` rows, inserting blank
/// lines at the top so the block's content starts at row `top_offset`.
fn vpad_at(b : Block, target : Int, top_offset : Int) -> Array[String] {
  let h = b.lines.length()
  guard h < target else { b.lines }
  let empty = " ".repeat(b.width)
  let top = Array::make(top_offset, empty)
  let bottom = Array::make((target - top_offset - h).max(0), empty)
  top + b.lines + bottom
}
