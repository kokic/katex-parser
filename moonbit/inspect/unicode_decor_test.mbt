///|
test "horiz braces keep their name and label" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\overbrace{a}^{b}")),
    "overbrace(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\underbrace{a}_{b}")),
    "underbrace(a)_b",
  )
  // bracket variants keep their identity
  @test.assert_eq(
    @unicode.render(@katex.parse("\\overbracket{a}^{b}")),
    "overbracket(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\underbracket{a}_{b}")),
    "underbracket(a)_b",
  )
}

///|
test "extended arrows keep direction and labels" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\xleftarrow{a}^{b}")),
    "xleftarrow(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\xrightarrow{a}^{b}")),
    "xrightarrow(a)ᵇ",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\xRightarrow{a}^{b}")),
    "xRightarrow(a)ᵇ",
  )
  @test.assert_eq(@unicode.render(@katex.parse("\\xmapsto{a}")), "xmapsto(a)")
  // optional below label becomes a second argument
  @test.assert_eq(
    @unicode.render(@katex.parse("\\xrightarrow[below]{above}")),
    "xrightarrow(above,below)",
  )
}
