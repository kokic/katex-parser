///|
test "horiz braces keep their name and label" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\overbrace{a}^{b}")),
    "overbrace(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\underbrace{a}_{b}")),
    "underbrace(a)_b",
  )
  // bracket variants keep their identity
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\overbracket{a}^{b}")),
    "overbracket(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\underbracket{a}_{b}")),
    "underbracket(a)_b",
  )
}

///|
test "extended arrows keep direction and labels" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\xleftarrow{a}^{b}")),
    "xleftarrow(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\xrightarrow{a}^{b}")),
    "xrightarrow(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\xRightarrow{a}^{b}")),
    "xRightarrow(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\xmapsto{a}")),
    "xmapsto(a)",
  )
  // optional below label becomes a second argument
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\xrightarrow[below]{above}")),
    "xrightarrow(above,below)",
  )
}
