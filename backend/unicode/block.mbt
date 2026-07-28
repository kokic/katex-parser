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
  if target_width <= self.width {
    return self
  }
  let lines = self.lines.map(fn(l) { pad_right(l, target_width) })
  { lines, width: target_width }
}

///|
pub fn Block::center(self : Block, target_width : Int) -> Block {
  if self.lines.length() == 0 || target_width <= self.width {
    return self
  }
  let lines = self.lines.map(fn(l) { center_text(l, target_width) })
  { lines, width: target_width }
}

///|
/// Vertical concatenation. The narrower block is padded to match width.
pub fn Block::above(self : Block, other : Block) -> Block {
  let new_w = max(self.width, other.width)
  let self_lines = self.lines.map(fn(l) { pad_right(l, new_w) })
  let other_lines = other.lines.map(fn(l) { pad_right(l, new_w) })
  { lines: self_lines + other_lines, width: new_w }
}

///|
/// Horizontal concatenation, vertically centering the shorter block.
pub fn Block::beside(self : Block, other : Block) -> Block {
  let new_h = max(self.lines.length(), other.lines.length())
  let self_padded = vpad(self, new_h)
  let other_padded = vpad(other, new_h)
  let new_w = self.width + other.width
  let lines = Array::makei(new_h, fn(i) { self_padded[i] + other_padded[i] })
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
  if self.lines.length() == 0 {
    return Block::from("\{left}\{right}")
  }
  let lines = self.lines.map(fn(l) { "\{left}\{l}\{right}" })
  { lines, width: self.width + left.length() + right.length() }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

///|
fn pad_right(s : String, width : Int) -> String {
  let need = width - s.length()
  if need <= 0 { s } else { s + " ".repeat(need) }
}

///|
fn center_text(s : String, width : Int) -> String {
  let need = width - s.length()
  if need <= 0 {
    return s
  }
  let left = need / 2
  let right = need - left
  " ".repeat(left) + s + " ".repeat(right)
}

///|
/// Vertically pad a block so it has exactly `target` rows. Extra rows are
/// filled with blank (space-only) lines, evenly distributed above and below.
fn vpad(b : Block, target : Int) -> Array[String] {
  if b.lines.length() >= target {
    return b.lines
  }
  let total_pad = target - b.lines.length()
  let top_pad = total_pad / 2
  let bottom_pad = total_pad - top_pad
  let empty = " ".repeat(b.width)
  let top = Array::make(top_pad, empty)
  let bottom = Array::make(bottom_pad, empty)
  top + b.lines + bottom
}

///|
fn max(a : Int, b : Int) -> Int {
  if a > b { a } else { b }
}
