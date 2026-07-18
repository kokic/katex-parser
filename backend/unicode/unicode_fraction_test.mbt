///|
test "render binomial without fraction bar" {
  @test.assert_eq(render(@katex_parser.parse("\\binom{n}{k}")), "(n,k)")
}

///|
test "render nested fractions" {
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{\\frac{a}{b}}{c}")),
    "(a∕b)∕c",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a}{\\frac{b}{c}}")),
    "a∕(b∕c)",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a+b}{c+d}")),
    "(a+b)∕(c+d)",
  )
}
