///|
test "render Unicode symbols and scripts" {
  @test.assert_eq(
    render(@katex_parser.parse("\\alpha_2^n + \\beta")),
    "α₂ⁿ+β",
  )
}

///|
test "render structural nodes without losing information" {
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a}{b}+\\sqrt[3]{x}+\\overline y")),
    "a∕b+³√x+overline(y)",
  )
}

///|
test "use UnicodeMath syntax for unsupported scripts" {
  @test.assert_eq(render(@katex_parser.parse("x^{q}")), "x^q")
}

///|
test "retain non-Unicode root indices as UnicodeMath" {
  @test.assert_eq(render(@katex_parser.parse("\\sqrt[q]{x}")), "root(q,x)")
}

///|
test "parenthesize compound radical bodies" {
  @test.assert_eq(render(@katex_parser.parse("\\sqrt{x}")), "√x")
  @test.assert_eq(render(@katex_parser.parse("\\sqrt{x+y}")), "√(x+y)")
}

///|
test "preserve grouping for fraction and script operands" {
  @test.assert_eq(render(@katex_parser.parse("\\frac{a+b}{c}")), "(a+b)∕c")
  @test.assert_eq(render(@katex_parser.parse("{\\frac{a}{b}}^2")), "(a∕b)²")
}

///|
test "use combining accents only for atomic bodies" {
  @test.assert_eq(render(@katex_parser.parse("\\hat{x}")), "x̂")
  @test.assert_eq(render(@katex_parser.parse("\\hat{x+y}")), "\\hat(x+y)")
}
