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
  let width = raw.fold(init=0, (m, l) => m.max(display_width(l.to_owned())))
  let lines = raw.map(l => pad_right(l.to_owned(), width))
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
    width: self.width + display_width(left) + display_width(right),
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
  let need = width - display_width(s)
  guard need > 0 else { s }
  s + " ".repeat(need)
}

///|
/// Compute the maximum width per column across all rows of cell strings.
pub fn column_widths(cells : Array[Array[String]]) -> Array[Int] {
  column_max_widths(cells, display_width)
}

///|
/// Compute the maximum width per column of any row-shaped table, where each
/// cell's width comes from `width_of`.
fn[W] column_max_widths(
  rows : Array[Array[W]],
  width_of : (W) -> Int,
) -> Array[Int] {
  let max_cols = rows.fold(init=0, (m, row) => m.max(row.length()))
  let widths = Array::make(max_cols, 0)
  for row in rows {
    for j, cell in row {
      let w = width_of(cell)
      if w > widths[j] {
        widths[j] = w
      }
    }
  }
  widths
}

///|
fn center_text(s : String, width : Int) -> String {
  let need = width - display_width(s)
  guard need > 0 else { s }
  let left = need / 2
  let right = need - left
  " ".repeat(left) + s + " ".repeat(right)
}

// ---------------------------------------------------------------------------
// Display width
// ---------------------------------------------------------------------------

///|
/// Terminal display width (in columns) of a string, counting full-width
/// characters as 2 and combining/zero-width marks as 0. Unlike `length()`,
/// this is based on Unicode code points, so astral-plane characters (e.g.
/// math alphanumerics like 𝟙) count as their on-screen width of 1.
pub fn display_width(s : String) -> Int {
  let mut w = 0
  for c in s.iter() {
    w = w + char_width(c)
  }
  w
}

///|
fn char_width(c : Char) -> Int {
  let code = c.to_int()
  guard code > 0 else { 0 }
  if is_zero_width_mark(code) {
    0
  } else if is_east_asian_wide(code) {
    2
  } else {
    1
  }
}

///|
/// Zero-width marks: combining diacritics (Mn/Me), variation selectors, and
/// zero-width format characters.
fn is_zero_width_mark(code : Int) -> Bool {
  code <= 0x1F ||
  code == 0x7F ||
  (0x80 <= code && code <= 0x9F) ||
  (0x0300 <= code && code <= 0x036F) ||
  (0x0483 <= code && code <= 0x0489) ||
  (0x0591 <= code && code <= 0x05BD) ||
  code == 0x05BF ||
  (0x05C1 <= code && code <= 0x05C2) ||
  (0x05C4 <= code && code <= 0x05C5) ||
  code == 0x05C7 ||
  (0x0610 <= code && code <= 0x061A) ||
  (0x064B <= code && code <= 0x065F) ||
  code == 0x0670 ||
  (0x06D6 <= code && code <= 0x06DC) ||
  (0x06DF <= code && code <= 0x06E4) ||
  (0x06E7 <= code && code <= 0x06E8) ||
  (0x06EA <= code && code <= 0x06ED) ||
  code == 0x0711 ||
  (0x0730 <= code && code <= 0x074A) ||
  (0x07A6 <= code && code <= 0x07B0) ||
  (0x07EB <= code && code <= 0x07F3) ||
  (0x0816 <= code && code <= 0x0819) ||
  (0x081B <= code && code <= 0x0823) ||
  (0x0825 <= code && code <= 0x0827) ||
  (0x0829 <= code && code <= 0x082D) ||
  (0x0859 <= code && code <= 0x085B) ||
  (0x08D3 <= code && code <= 0x08E1) ||
  (0x08E3 <= code && code <= 0x0902) ||
  (0x093A <= code && code <= 0x093C) ||
  (0x0941 <= code && code <= 0x0948) ||
  code == 0x094D ||
  (0x0951 <= code && code <= 0x0957) ||
  (0x0962 <= code && code <= 0x0963) ||
  (0x0981 <= code && code <= 0x0983) ||
  code == 0x09BC ||
  (0x09BE <= code && code <= 0x09C4) ||
  (0x09C7 <= code && code <= 0x09C8) ||
  (0x09CB <= code && code <= 0x09CD) ||
  (0x09D7 <= code && code <= 0x09D7) ||
  (0x09E2 <= code && code <= 0x09E3) ||
  (0x0A01 <= code && code <= 0x0A03) ||
  code == 0x0A3C ||
  (0x0A3E <= code && code <= 0x0A42) ||
  (0x0A47 <= code && code <= 0x0A48) ||
  (0x0A4B <= code && code <= 0x0A4D) ||
  code == 0x0A51 ||
  (0x0A70 <= code && code <= 0x0A71) ||
  code == 0x0A75 ||
  (0x0A81 <= code && code <= 0x0A83) ||
  code == 0x0ABC ||
  (0x0ABE <= code && code <= 0x0AC5) ||
  (0x0AC7 <= code && code <= 0x0AC9) ||
  (0x0ACB <= code && code <= 0x0ACD) ||
  (0x0AE2 <= code && code <= 0x0AE3) ||
  (0x0B01 <= code && code <= 0x0B03) ||
  code == 0x0B3C ||
  (0x0B3E <= code && code <= 0x0B44) ||
  (0x0B47 <= code && code <= 0x0B48) ||
  (0x0B4B <= code && code <= 0x0B4D) ||
  code == 0x0B57 ||
  (0x0B62 <= code && code <= 0x0B63) ||
  code == 0x0B82 ||
  code == 0x0BBE ||
  code == 0x0BC0 ||
  code == 0x0BCD ||
  (0x0BD7 <= code && code <= 0x0BD7) ||
  (0x0C00 <= code && code <= 0x0C04) ||
  code == 0x0C3E ||
  (0x0C40 <= code && code <= 0x0C44) ||
  (0x0C46 <= code && code <= 0x0C48) ||
  (0x0C4A <= code && code <= 0x0C4D) ||
  (0x0C55 <= code && code <= 0x0C56) ||
  (0x0C62 <= code && code <= 0x0C63) ||
  (0x0C81 <= code && code <= 0x0C83) ||
  code == 0x0CBC ||
  (0x0CBE <= code && code <= 0x0CC4) ||
  (0x0CC6 <= code && code <= 0x0CC8) ||
  (0x0CCA <= code && code <= 0x0CCD) ||
  (0x0CD5 <= code && code <= 0x0CD6) ||
  (0x0CE2 <= code && code <= 0x0CE3) ||
  (0x0D01 <= code && code <= 0x0D03) ||
  code == 0x0D3E ||
  (0x0D40 <= code && code <= 0x0D44) ||
  (0x0D46 <= code && code <= 0x0D48) ||
  (0x0D4A <= code && code <= 0x0D4D) ||
  code == 0x0D57 ||
  (0x0D62 <= code && code <= 0x0D63) ||
  code == 0x0D82 ||
  code == 0x0D83 ||
  (0x0DCA <= code && code <= 0x0DCA) ||
  (0x0DD2 <= code && code <= 0x0DD4) ||
  code == 0x0DD6 ||
  (0x0E31 <= code && code <= 0x0E31) ||
  (0x0E34 <= code && code <= 0x0E3A) ||
  (0x0E47 <= code && code <= 0x0E4E) ||
  code == 0x0EB1 ||
  (0x0EB4 <= code && code <= 0x0EB9) ||
  (0x0EBB <= code && code <= 0x0EBC) ||
  (0x0EC8 <= code && code <= 0x0ECD) ||
  (0x0F18 <= code && code <= 0x0F19) ||
  code == 0x0F35 ||
  code == 0x0F37 ||
  code == 0x0F39 ||
  (0x0F71 <= code && code <= 0x0F84) ||
  (0x0F86 <= code && code <= 0x0F87) ||
  (0x0F8D <= code && code <= 0x0F97) ||
  (0x0F99 <= code && code <= 0x0FBC) ||
  code == 0x0FC6 ||
  (0x102D <= code && code <= 0x1030) ||
  (0x1032 <= code && code <= 0x1037) ||
  (0x1039 <= code && code <= 0x103A) ||
  (0x103D <= code && code <= 0x103E) ||
  (0x1058 <= code && code <= 0x1059) ||
  (0x105E <= code && code <= 0x1060) ||
  (0x1071 <= code && code <= 0x1074) ||
  code == 0x1082 ||
  (0x1085 <= code && code <= 0x1086) ||
  code == 0x108D ||
  code == 0x109D ||
  (0x135D <= code && code <= 0x135F) ||
  (0x1712 <= code && code <= 0x1714) ||
  (0x1732 <= code && code <= 0x1734) ||
  (0x1752 <= code && code <= 0x1753) ||
  (0x1772 <= code && code <= 0x1773) ||
  (0x17B4 <= code && code <= 0x17B5) ||
  (0x17B7 <= code && code <= 0x17BD) ||
  code == 0x17C6 ||
  (0x17C9 <= code && code <= 0x17D3) ||
  code == 0x17DD ||
  (0x180B <= code && code <= 0x180D) ||
  code == 0x1885 ||
  code == 0x1886 ||
  (0x18A9 <= code && code <= 0x18A9) ||
  (0x1920 <= code && code <= 0x1922) ||
  (0x1927 <= code && code <= 0x1928) ||
  code == 0x1932 ||
  (0x1939 <= code && code <= 0x193B) ||
  (0x1A17 <= code && code <= 0x1A18) ||
  code == 0x1A1B ||
  code == 0x1A56 ||
  (0x1A58 <= code && code <= 0x1A5E) ||
  code == 0x1A60 ||
  code == 0x1A62 ||
  (0x1A65 <= code && code <= 0x1A6C) ||
  (0x1A73 <= code && code <= 0x1A7C) ||
  code == 0x1A7F ||
  (0x1AB0 <= code && code <= 0x1AC0) ||
  (0x1B00 <= code && code <= 0x1B03) ||
  code == 0x1B34 ||
  (0x1B36 <= code && code <= 0x1B3A) ||
  code == 0x1B3C ||
  code == 0x1B42 ||
  (0x1B6B <= code && code <= 0x1B73) ||
  (0x1B80 <= code && code <= 0x1B81) ||
  (0x1BA2 <= code && code <= 0x1BA5) ||
  (0x1BA8 <= code && code <= 0x1BA9) ||
  (0x1BAB <= code && code <= 0x1BAD) ||
  code == 0x1BE6 ||
  (0x1BE8 <= code && code <= 0x1BE9) ||
  code == 0x1BED ||
  (0x1BEF <= code && code <= 0x1BF1) ||
  (0x1C2C <= code && code <= 0x1C33) ||
  (0x1C36 <= code && code <= 0x1C37) ||
  (0x1CD0 <= code && code <= 0x1CD2) ||
  (0x1CD4 <= code && code <= 0x1CE0) ||
  (0x1CE2 <= code && code <= 0x1CE8) ||
  code == 0x1CED ||
  code == 0x1CF4 ||
  (0x1CF8 <= code && code <= 0x1CF9) ||
  (0x1DC0 <= code && code <= 0x1DF9) ||
  (0x1DFB <= code && code <= 0x1DFF) ||
  code == 0x200B ||
  code == 0x200C ||
  code == 0x200D ||
  code == 0x200E ||
  code == 0x200F ||
  (0x2028 <= code && code <= 0x202E) ||
  (0x2060 <= code && code <= 0x2064) ||
  (0x206A <= code && code <= 0x206F) ||
  (0x20D0 <= code && code <= 0x20F0) ||
  (0x2CEF <= code && code <= 0x2CF1) ||
  code == 0x2D7F ||
  (0x2DE0 <= code && code <= 0x2DFF) ||
  (0x302A <= code && code <= 0x302D) ||
  (0x3099 <= code && code <= 0x309A) ||
  (0xA66F <= code && code <= 0xA672) ||
  (0xA674 <= code && code <= 0xA67D) ||
  (0xA69E <= code && code <= 0xA69F) ||
  (0xA6F0 <= code && code <= 0xA6F1) ||
  code == 0xA802 ||
  code == 0xA806 ||
  code == 0xA80B ||
  (0xA825 <= code && code <= 0xA826) ||
  (0xA8C4 <= code && code <= 0xA8C5) ||
  (0xA8E0 <= code && code <= 0xA8F1) ||
  code == 0xA926 ||
  (0xA927 <= code && code <= 0xA92D) ||
  (0xA947 <= code && code <= 0xA951) ||
  (0xA980 <= code && code <= 0xA982) ||
  code == 0xA9B3 ||
  (0xA9B6 <= code && code <= 0xA9B9) ||
  (0xA9BC <= code && code <= 0xA9BD) ||
  code == 0xA9E5 ||
  (0xAA29 <= code && code <= 0xAA2E) ||
  (0xAA31 <= code && code <= 0xAA32) ||
  (0xAA35 <= code && code <= 0xAA36) ||
  code == 0xAA43 ||
  code == 0xAA4C ||
  code == 0xAA7C ||
  (0xAAB0 <= code && code <= 0xAAB0) ||
  code == 0xAAB2 ||
  code == 0xAAB3 ||
  code == 0xAAB4 ||
  (0xAAB7 <= code && code <= 0xAAB8) ||
  code == 0xAABE ||
  code == 0xAABF ||
  code == 0xAAC1 ||
  code == 0xAAEC ||
  code == 0xAAED ||
  code == 0xAAF6 ||
  (0xABE5 <= code && code <= 0xABE5) ||
  (0xABE8 <= code && code <= 0xABE8) ||
  code == 0xABED ||
  code == 0xFB1E ||
  (0xFE00 <= code && code <= 0xFE0F) ||
  (0xFE20 <= code && code <= 0xFE2F) ||
  code == 0xFEFF ||
  (0x101FD <= code && code <= 0x101FD) ||
  (0x102E0 <= code && code <= 0x102E0) ||
  (0x10376 <= code && code <= 0x1037A) ||
  (0x10A01 <= code && code <= 0x10A03) ||
  (0x10A05 <= code && code <= 0x10A06) ||
  (0x10A0C <= code && code <= 0x10A0F) ||
  (0x10A38 <= code && code <= 0x10A3A) ||
  code == 0x10A3F ||
  (0x10AE5 <= code && code <= 0x10AE6) ||
  (0x11001 <= code && code <= 0x11001) ||
  (0x11038 <= code && code <= 0x11046) ||
  (0x1107F <= code && code <= 0x11081) ||
  (0x110B3 <= code && code <= 0x110B6) ||
  (0x110B9 <= code && code <= 0x110BA) ||
  (0x11100 <= code && code <= 0x11102) ||
  (0x11127 <= code && code <= 0x1112B) ||
  (0x1112D <= code && code <= 0x11134) ||
  (0x11173 <= code && code <= 0x11173) ||
  (0x11180 <= code && code <= 0x11181) ||
  (0x111B6 <= code && code <= 0x111BE) ||
  (0x111CA <= code && code <= 0x111CC) ||
  (0x1122F <= code && code <= 0x11231) ||
  (0x11234 <= code && code <= 0x11234) ||
  (0x11236 <= code && code <= 0x11237) ||
  (0x1123E <= code && code <= 0x1123E) ||
  (0x112DF <= code && code <= 0x112DF) ||
  (0x112E3 <= code && code <= 0x112EA) ||
  (0x11300 <= code && code <= 0x11303) ||
  (0x1133B <= code && code <= 0x1133C) ||
  code == 0x1133E ||
  (0x11340 <= code && code <= 0x11340) ||
  (0x11357 <= code && code <= 0x11357) ||
  (0x11366 <= code && code <= 0x1136C) ||
  (0x11370 <= code && code <= 0x11374) ||
  (0x11438 <= code && code <= 0x1143F) ||
  (0x11442 <= code && code <= 0x11444) ||
  (0x11446 <= code && code <= 0x11446) ||
  (0x1145E <= code && code <= 0x1145E) ||
  (0x114B3 <= code && code <= 0x114B8) ||
  (0x114BA <= code && code <= 0x114BA) ||
  (0x114BF <= code && code <= 0x114C0) ||
  (0x114C2 <= code && code <= 0x114C3) ||
  (0x115B2 <= code && code <= 0x115B5) ||
  (0x115BC <= code && code <= 0x115BD) ||
  (0x115BF <= code && code <= 0x115C0) ||
  (0x115DC <= code && code <= 0x115DD) ||
  (0x11633 <= code && code <= 0x1163A) ||
  (0x1163D <= code && code <= 0x1163D) ||
  (0x1163F <= code && code <= 0x11640) ||
  (0x116AB <= code && code <= 0x116AB) ||
  (0x116AD <= code && code <= 0x116AD) ||
  (0x116B0 <= code && code <= 0x116B5) ||
  code == 0x116B7 ||
  (0x1171D <= code && code <= 0x1171F) ||
  (0x11722 <= code && code <= 0x11725) ||
  (0x11727 <= code && code <= 0x1172B) ||
  (0x1182F <= code && code <= 0x11837) ||
  (0x11839 <= code && code <= 0x1183A) ||
  (0x11A01 <= code && code <= 0x11A0A) ||
  (0x11A33 <= code && code <= 0x11A38) ||
  (0x11A3B <= code && code <= 0x11A3E) ||
  code == 0x11A47 ||
  (0x11A51 <= code && code <= 0x11A56) ||
  (0x11A59 <= code && code <= 0x11A5B) ||
  code == 0x11A8A ||
  (0x11A8C <= code && code <= 0x11A96) ||
  code == 0x11A98 ||
  code == 0x11A99 ||
  (0x11C30 <= code && code <= 0x11C36) ||
  (0x11C38 <= code && code <= 0x11C3D) ||
  (0x11C3F <= code && code <= 0x11C3F) ||
  (0x11C92 <= code && code <= 0x11CA7) ||
  (0x11CAA <= code && code <= 0x11CB0) ||
  (0x11CB2 <= code && code <= 0x11CB3) ||
  (0x11CB5 <= code && code <= 0x11CB6) ||
  (0x11D31 <= code && code <= 0x11D36) ||
  (0x11D3A <= code && code <= 0x11D3A) ||
  (0x11D3C <= code && code <= 0x11D3D) ||
  (0x11D3F <= code && code <= 0x11D45) ||
  code == 0x11D47 ||
  (0x16AF0 <= code && code <= 0x16AF4) ||
  (0x16B30 <= code && code <= 0x16B36) ||
  (0x16F8F <= code && code <= 0x16F92) ||
  (0x1BC9D <= code && code <= 0x1BC9E) ||
  (0x1D165 <= code && code <= 0x1D169) ||
  (0x1D16D <= code && code <= 0x1D172) ||
  (0x1D17B <= code && code <= 0x1D182) ||
  (0x1D185 <= code && code <= 0x1D18B) ||
  (0x1D1AA <= code && code <= 0x1D1AD) ||
  (0x1D242 <= code && code <= 0x1D244) ||
  (0x1DA00 <= code && code <= 0x1DA36) ||
  (0x1DA3B <= code && code <= 0x1DA6C) ||
  (0x1DA75 <= code && code <= 0x1DA75) ||
  (0x1DA84 <= code && code <= 0x1DA84) ||
  (0x1DA9B <= code && code <= 0x1DA9F) ||
  (0x1DAA1 <= code && code <= 0x1DAAF) ||
  (0x1E000 <= code && code <= 0x1E006) ||
  (0x1E008 <= code && code <= 0x1E018) ||
  (0x1E01B <= code && code <= 0x1E021) ||
  (0x1E023 <= code && code <= 0x1E024) ||
  (0x1E026 <= code && code <= 0x1E02A) ||
  (0x1E8D0 <= code && code <= 0x1E8D6) ||
  (0x1E944 <= code && code <= 0x1E94A) ||
  (0xE0100 <= code && code <= 0xE01EF)
}

///|
/// East Asian Wide or Fullwidth code points, displayed as two columns wide.
fn is_east_asian_wide(code : Int) -> Bool {
  (0x1100 <= code && code <= 0x115F) ||
  (0x231A <= code && code <= 0x231B) ||
  (0x2329 <= code && code <= 0x232A) ||
  (0x23E9 <= code && code <= 0x23EC) ||
  code == 0x23F0 ||
  code == 0x23F3 ||
  (0x25FD <= code && code <= 0x25FE) ||
  (0x2614 <= code && code <= 0x2615) ||
  (0x2648 <= code && code <= 0x2653) ||
  code == 0x267F ||
  code == 0x2693 ||
  code == 0x26A1 ||
  (0x26AA <= code && code <= 0x26AB) ||
  (0x26BD <= code && code <= 0x26BE) ||
  (0x26C4 <= code && code <= 0x26C5) ||
  code == 0x26CE ||
  code == 0x26D4 ||
  code == 0x26EA ||
  (0x26F2 <= code && code <= 0x26F3) ||
  code == 0x26F5 ||
  code == 0x26FA ||
  code == 0x26FD ||
  code == 0x2705 ||
  (0x270A <= code && code <= 0x270B) ||
  code == 0x2728 ||
  code == 0x274C ||
  code == 0x274E ||
  (0x2753 <= code && code <= 0x2755) ||
  code == 0x2757 ||
  (0x2795 <= code && code <= 0x2797) ||
  code == 0x27B0 ||
  code == 0x27BF ||
  (0x2B1B <= code && code <= 0x2B1C) ||
  code == 0x2B50 ||
  code == 0x2B55 ||
  (0x2E80 <= code && code <= 0x2E99) ||
  (0x2E9B <= code && code <= 0x2EF3) ||
  (0x2F00 <= code && code <= 0x2FD5) ||
  (0x2FF0 <= code && code <= 0x2FFB) ||
  (0x3000 <= code && code <= 0x303E) ||
  (0x3041 <= code && code <= 0x3096) ||
  (0x3099 <= code && code <= 0x30FF) ||
  (0x3105 <= code && code <= 0x312F) ||
  (0x3131 <= code && code <= 0x318E) ||
  (0x3190 <= code && code <= 0x31BA) ||
  (0x31C0 <= code && code <= 0x31E3) ||
  (0x31F0 <= code && code <= 0x321E) ||
  (0x3220 <= code && code <= 0x3247) ||
  (0x3250 <= code && code <= 0x4DBF) ||
  (0x4E00 <= code && code <= 0xA4C6) ||
  (0xA960 <= code && code <= 0xA97C) ||
  (0xAC00 <= code && code <= 0xD7A3) ||
  (0xF900 <= code && code <= 0xFAFF) ||
  (0xFE10 <= code && code <= 0xFE19) ||
  (0xFE30 <= code && code <= 0xFE52) ||
  (0xFE54 <= code && code <= 0xFE66) ||
  (0xFE68 <= code && code <= 0xFE6B) ||
  (0xFF00 <= code && code <= 0xFF60) ||
  (0xFFE0 <= code && code <= 0xFFE6) ||
  (0x16FE0 <= code && code <= 0x16FE4) ||
  (0x17000 <= code && code <= 0x187F7) ||
  (0x18800 <= code && code <= 0x18CD5) ||
  (0x1B000 <= code && code <= 0x1B2FB) ||
  code == 0x1F004 ||
  code == 0x1F0CF ||
  code == 0x1F18E ||
  (0x1F191 <= code && code <= 0x1F19A) ||
  (0x1F200 <= code && code <= 0x1F202) ||
  (0x1F210 <= code && code <= 0x1F23B) ||
  (0x1F240 <= code && code <= 0x1F248) ||
  (0x1F250 <= code && code <= 0x1F251) ||
  (0x1F260 <= code && code <= 0x1F265) ||
  (0x1F300 <= code && code <= 0x1F320) ||
  (0x1F32D <= code && code <= 0x1F335) ||
  (0x1F337 <= code && code <= 0x1F37C) ||
  (0x1F37E <= code && code <= 0x1F393) ||
  (0x1F3A0 <= code && code <= 0x1F3CA) ||
  (0x1F3CF <= code && code <= 0x1F3D3) ||
  (0x1F3E0 <= code && code <= 0x1F3F0) ||
  (0x1F3F4 <= code && code <= 0x1F3F4) ||
  (0x1F3F8 <= code && code <= 0x1F43E) ||
  (0x1F440 <= code && code <= 0x1F440) ||
  (0x1F442 <= code && code <= 0x1F4FC) ||
  (0x1F4FF <= code && code <= 0x1F53D) ||
  (0x1F54B <= code && code <= 0x1F54E) ||
  (0x1F550 <= code && code <= 0x1F567) ||
  (0x1F57A <= code && code <= 0x1F57A) ||
  (0x1F595 <= code && code <= 0x1F596) ||
  (0x1F5A4 <= code && code <= 0x1F5A4) ||
  (0x1F5FB <= code && code <= 0x1F64F) ||
  (0x1F680 <= code && code <= 0x1F6C5) ||
  (0x1F6CC <= code && code <= 0x1F6CC) ||
  (0x1F6D0 <= code && code <= 0x1F6D2) ||
  (0x1F6D5 <= code && code <= 0x1F6D7) ||
  (0x1F6EB <= code && code <= 0x1F6EC) ||
  (0x1F6F4 <= code && code <= 0x1F6FC) ||
  (0x1F7E0 <= code && code <= 0x1F7EB) ||
  (0x1F90C <= code && code <= 0x1F93A) ||
  (0x1F93C <= code && code <= 0x1F945) ||
  (0x1F947 <= code && code <= 0x1F978) ||
  (0x1F97A <= code && code <= 0x1F9CB) ||
  (0x1F9CD <= code && code <= 0x1F9FF) ||
  (0x1FA70 <= code && code <= 0x1FA74) ||
  (0x1FA78 <= code && code <= 0x1FA7A) ||
  (0x1FA80 <= code && code <= 0x1FA86) ||
  (0x1FA90 <= code && code <= 0x1FAA8) ||
  (0x1FAB0 <= code && code <= 0x1FAB6) ||
  (0x1FAC0 <= code && code <= 0x1FAC2) ||
  (0x1FAD0 <= code && code <= 0x1FAD6) ||
  (0x20000 <= code && code <= 0x2FFFD) ||
  (0x30000 <= code && code <= 0x3FFFD)
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
