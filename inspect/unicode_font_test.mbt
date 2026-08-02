///|
test "Font node treated as atomic for operand grouping" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\R_1")), "ℝ₁")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\R^2")), "ℝ²")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\R_1^2")), "ℝ₁²")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{\\R}{2}")),
    "ℝ∕2",
  )
  // Font with unmappable body still atomic (self-delimiting notation)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{\\mathbb{abc}}{2}")),
    "𝕒𝕓𝕔∕2",
  )
}

///|
test "map font characters individually" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{ab}")),
    "𝐚𝐛",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{abc}")),
    "𝐚𝐛𝐜",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathbb{R}")), "ℝ")
  // Letters with a mapped bold variant render directly
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{a\\alpha b}")),
    "𝐚𝛂𝐛",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{\\alpha\\beta}")),
    "𝛂𝛃",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{\\Gamma\\Omega}")),
    "𝚪𝛀",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\boldsymbol{\\alpha}")),
    "𝜶",
  )
  // Symbols with no font variant render as-is
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{x+y}")),
    "𝐱+𝐲",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{x=y}")),
    "𝐱=𝐲",
  )
}
