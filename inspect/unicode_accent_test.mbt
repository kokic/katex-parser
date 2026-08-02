///|
test "use combining accents only for atomic bodies" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\hat{x}")), "x̂")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\hat{x+y}")),
    "hat(x + y)",
  )
}

///|
test "render all combining accent commands" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\acute{x}")), "x́")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\grave{x}")), "x̀")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\ddot{x}")), "ẍ")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\tilde{x}")), "x̃")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\bar{x}")), "x̄")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\breve{x}")), "x̆")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\check{x}")), "x̌")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\dot{x}")), "ẋ")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathring{x}")), "x̊")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\vec{x}")), "x⃗")
}

///|
test "accent uses function notation for multi-character bases" {
  // Multi-char base — no combining mark
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\hat{\\overline{x}}")),
    "hat(overline(x))",
  )
  // LeftRight is multi-char — function notation
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\hat{\\left(x\\right)}")),
    "hat((x))",
  )
  // Single-char base still gets combining mark
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\hat{x}")), "x̂")
}
