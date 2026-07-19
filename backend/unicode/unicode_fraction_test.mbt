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

///|
test "render fractions in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a}{b}", settings~)),
    " a \n---\n b ",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a}{bc}", settings~)),
    " a  \n----\n bc ",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{xy}{z}", settings~)),
    " xy \n----\n z  ",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a^2}{b+c}", settings~)),
    " a²  \n-----\n b+c ",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\dfrac{x}{y}", settings~)),
    " x \n---\n y ",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\binom{n}{k}", settings~)),
    "(n,k)",
  )
}

///|
test "render fractions with configurable slash" {
  let config = RenderConfig::make(fraction_slash="/")
  @test.assert_eq(render(@katex_parser.parse("\\frac{a}{b}"), config~), "a/b")
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a+b}{c+d}"), config~),
    "(a+b)/(c+d)",
  )
}
