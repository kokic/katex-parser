///|
test "named operators keep a space before their operand" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det A")), "det A")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\sin x")), "sin x")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\lim f")), "lim f")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det A_1")), "det A₁")
  // Opening delimiters already provide visual separation
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det(x)")), "det(x)")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\det\\left(x\\right)")),
    "det(x)",
  )
}

///|
test "strip backslash prefix in fallback notation" {
  // Named operators render without the backslash
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\sin")), "sin")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\lim_{x}")), "limₓ")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det A")), "det A")
  // Nested fallbacks strip each level's backslash
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\widehat{\\overrightarrow{x}}")),
    "widehat(overrightarrow(x))",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\hat{\\cancel{x}}")),
    "hat(cancel(x))",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\underleftrightarrow{x}")),
    "underaccent(underleftrightarrow,x)",
  )
}
