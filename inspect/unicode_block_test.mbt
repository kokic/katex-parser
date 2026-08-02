///|
test "Block::from and render" {
  let b = @unicode.Block::from("hello")
  @test.assert_eq(b.render(), "hello")
  @test.assert_eq(b.height(), 1)
  @test.assert_eq(b.width(), 5)
}

///|
test "Block::empty" {
  let b = @unicode.Block::empty()
  @test.assert_eq(b.render(), "")
  @test.assert_eq(b.height(), 0)
  @test.assert_eq(b.width(), 0)
}

///|
test "Block::pad_to" {
  let b = @unicode.Block::from("ab")
  let padded = b.pad_to(5)
  @test.assert_eq(padded.render(), "ab   ")
  @test.assert_eq(padded.width(), 5)
  @test.assert_eq(b.pad_to(2).render(), "ab")
  @test.assert_eq(b.pad_to(0).render(), "ab")
}

///|
test "Block::center" {
  let b = @unicode.Block::from("ab")
  let centered = b.center(6)
  @test.assert_eq(centered.render(), "  ab  ")
  @test.assert_eq(centered.width(), 6)
  let b2 = @unicode.Block::from("a")
  @test.assert_eq(b2.center(4).render(), " a  ")
}

///|
test "Block::above same width" {
  let a = @unicode.Block::from("ab")
  let b = @unicode.Block::from("cd")
  let stacked = a.above(b)
  let output =
    #|ab
    #|cd
  @test.assert_eq(stacked.render(), output)
  @test.assert_eq(stacked.height(), 2)
  @test.assert_eq(stacked.width(), 2)
}

///|
test "Block::above narrow padded to match" {
  let a = @unicode.Block::from("ab")
  let b = @unicode.Block::from("xyz")
  let stacked = a.above(b)
  let output =
    #|ab 
    #|xyz
  @test.assert_eq(stacked.render(), output)
  @test.assert_eq(stacked.width(), 3)
}

///|
test "Block::above reverse narrow padded" {
  let a = @unicode.Block::from("xyz")
  let b = @unicode.Block::from("a")
  let stacked = a.above(b)
  let output =
    #|xyz
    #|a  
  @test.assert_eq(stacked.render(), output)
  @test.assert_eq(stacked.width(), 3)
}

///|
test "Block::beside same height" {
  let a = @unicode.Block::from("ab")
  let b = @unicode.Block::from("xy")
  let side = a.beside(b)
  @test.assert_eq(side.render(), "abxy")
  @test.assert_eq(side.height(), 1)
  @test.assert_eq(side.width(), 4)
}

///|
test "Block::enclose single line" {
  let b = @unicode.Block::from("abc")
  let enclosed = b.enclose("(", ")")
  @test.assert_eq(enclosed.render(), "(abc)")
  @test.assert_eq(enclosed.width(), 5)
}

///|
test "Block::enclose multi-line" {
  let b = @unicode.Block::from("aa").above(@unicode.Block::from("b"))
  let enclosed = b.enclose("[", "]")
  let output =
    #|[aa]
    #|[b ]
  @test.assert_eq(enclosed.render(), output)
}

// ---------------------------------------------------------------------------
// Composition scenarios — Block's purpose is aligning multi-line displays
// with labels, delimiters, and other block elements.
// ---------------------------------------------------------------------------

///|
/// M = [a  b]
///     [c  d]
test "label beside 2-row matrix (top-aligned)" {
  let rows = @unicode.Block::from("a  b").above(@unicode.Block::from("c  d"))
  let matrix = rows.enclose("[", "]")
  let label = @unicode.Block::from("M = ")
  let result = matrix.append_left(label)
  // 1-line label beside 2-line matrix: top_pad=0, bottom_pad=1
  let output =
    #|M = [a  b]
    #|    [c  d]
  @test.assert_eq(result.render(), output)
}

///|
/// M = [a]
///     [b]
///     [c]
test "label beside 3-row matrix (top-aligned)" {
  let rows = @unicode.Block::from("a")
    .above(@unicode.Block::from("b"))
    .above(@unicode.Block::from("c"))
  let matrix = rows.enclose("[", "]")
  let label = @unicode.Block::from("M = ")
  let result = matrix.append_left(label)
  // 1-line label beside 3-line matrix: both share baseline 0 → top-aligned
  let output =
    #|M = [a]
    #|    [b]
    #|    [c]
  @test.assert_eq(result.render(), output)
}

///|
/// M = [aa  b  ]
///     [c   ddd]
test "label beside 2-row matrix with uneven column widths" {
  let rows = @unicode.Block::from("aa  b  ").above(
    @unicode.Block::from("c   ddd"),
  )
  let matrix = rows.enclose("[", "]")
  let label = @unicode.Block::from("M = ")
  let result = matrix.append_left(label)
  let output =
    #|M = [aa  b  ]
    #|    [c   ddd]
  @test.assert_eq(result.render(), output)
}

///|
/// r = p/q in display:
///      p
/// r = ---
///      q
test "label beside fraction" {
  let num = @unicode.Block::from("p").center(3)
  let bar = @unicode.Block::from("---")
  let den = @unicode.Block::from("q").center(3)
  let frac = { ..num.above(bar).above(den), baseline: 1 }
  let label = @unicode.Block::from("r = ")
  let result = frac.append_left(label)
  // Fraction baseline = 1 (fraction bar line), label baseline = 0
  // Label aligns beside the fraction bar.
  let output =
    #|     p 
    #|r = ---
    #|     q 
  @test.assert_eq(result.render(), output)
}

///|
/// Larger fraction — alignment with uneven numerator/denominator widths:
///      p²
/// r = -----
///      q+1
test "label beside fraction with uneven width" {
  let num = @unicode.Block::from("p²").center(5)
  let bar = @unicode.Block::from("-----")
  let den = @unicode.Block::from("q+1").center(5)
  let frac = { ..num.above(bar).above(den), baseline: 1 }
  let label = @unicode.Block::from("r = ")
  let result = frac.append_left(label)
  let output =
    #|     p²  
    #|r = -----
    #|     q+1 
  @test.assert_eq(result.render(), output)
}

///|
/// Two 2-row blocks side by side — no gap between them.
/// [a][x]
/// [b][y]
test "two multi-line blocks side by side" {
  let left = @unicode.Block::from("[a]").above(@unicode.Block::from("[b]"))
  let right = @unicode.Block::from("[x]").above(@unicode.Block::from("[y]"))
  let result = left.beside(right)
  let output =
    #|[a][x]
    #|[b][y]
  @test.assert_eq(result.render(), output)
}

///|
/// Two blocks of different heights side by side:
/// [a][x]
/// [b][y]
///    [z]
test "two blocks of different heights side by side" {
  let left = @unicode.Block::from("[a]").above(@unicode.Block::from("[b]"))
  let right = @unicode.Block::from("[x]")
    .above(@unicode.Block::from("[y]"))
    .above(@unicode.Block::from("[z]"))
  let result = left.beside(right)
  // 2-row left beside 3-row right: left centered → top_pad=0, bottom_pad=1
  let output =
    #|[a][x]
    #|[b][y]
    #|   [z]
  @test.assert_eq(result.render(), output)
}

///|
/// [a  b],tag
/// [c  d]
test "append_right multi-line" {
  let rows = @unicode.Block::from("a  b").above(@unicode.Block::from("c  d"))
  let matrix = rows.enclose("[", "]")
  let tag = @unicode.Block::from(",tag")
  let result = matrix.append_right(tag)
  let output =
    #|[a  b],tag
    #|[c  d]    
  @test.assert_eq(result.render(), output)
}

///|
/// Enclose: matrix with parentheses
/// (a  b)
/// (c  d)
test "matrix with parentheses" {
  let rows = @unicode.Block::from("a  b").above(@unicode.Block::from("c  d"))
  let matrix = rows.enclose("(", ")")
  let output =
    #|(a  b)
    #|(c  d)
  @test.assert_eq(matrix.render(), output)
}

///|
/// Enclose: single-column matrix with parentheses
/// (a)
/// (b)
test "single-column matrix with parentheses" {
  let rows = @unicode.Block::from("a").above(@unicode.Block::from("b"))
  let matrix = rows.enclose("(", ")")
  let output =
    #|(a)
    #|(b)
  @test.assert_eq(matrix.render(), output)
}
