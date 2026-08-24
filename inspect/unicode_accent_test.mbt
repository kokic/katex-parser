///|
test "use combining accents only for atomic bodies" {
  @test.assert_eq(@unicode.render(@katex.parse("\\hat{x}")), "x̂")
  @test.assert_eq(@unicode.render(@katex.parse("\\hat{x+y}")), "hat(x + y)")
}

///|
test "render all combining accent commands" {
  @test.assert_eq(@unicode.render(@katex.parse("\\acute{x}")), "x́")
  @test.assert_eq(@unicode.render(@katex.parse("\\grave{x}")), "x̀")
  @test.assert_eq(@unicode.render(@katex.parse("\\ddot{x}")), "ẍ")
  @test.assert_eq(@unicode.render(@katex.parse("\\tilde{x}")), "x̃")
  @test.assert_eq(@unicode.render(@katex.parse("\\bar{x}")), "x̄")
  @test.assert_eq(@unicode.render(@katex.parse("\\breve{x}")), "x̆")
  @test.assert_eq(@unicode.render(@katex.parse("\\check{x}")), "x̌")
  @test.assert_eq(@unicode.render(@katex.parse("\\dot{x}")), "ẋ")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathring{x}")), "x̊")
  @test.assert_eq(@unicode.render(@katex.parse("\\vec{x}")), "x⃗")
}

///|
test "accent uses function notation for multi-character bases" {
  // Multi-char base — no combining mark
  @test.assert_eq(
    @unicode.render(@katex.parse("\\hat{\\overline{x}}")),
    "hat(overline(x))",
  )
  // LeftRight is multi-char — function notation
  @test.assert_eq(
    @unicode.render(@katex.parse("\\hat{\\left(x\\right)}")),
    "hat((x))",
  )
  // Single-char base still gets combining mark
  @test.assert_eq(@unicode.render(@katex.parse("\\hat{x}")), "x̂")
}
