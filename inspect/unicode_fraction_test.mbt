///|
test "render deep cfrac with baseline alignment" {
  let source =
    #|\frac{p}{q}=a_0+\cfrac{1}{a_1+\cfrac{1}{a_2+\cfrac{1}{a_3}}}

  let output =
    #| p               1       
    #|--- = a₀ + --------------
    #| q                 1     
    #|            a₁+--------- 
    #|                    1    
    #|                a₂+----  
    #|                    a₃   

  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse(source, settings~)),
    output,
  )
}

///|
test "render binomial without fraction bar" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\binom{n}{k}")),
    "(n,k)",
  )
}

///|
test "render nested fractions" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{\\frac{a}{b}}{c}")),
    "(a∕b)∕c",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{\\frac{b}{c}}")),
    "a∕(b∕c)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a+b}{c+d}")),
    "(a+b)∕(c+d)",
  )
}

///|
test "render fractions in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{b}", settings~)),
    " a \n---\n b ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{bc}", settings~)),
    " a  \n----\n bc ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{xy}{z}", settings~)),
    " xy \n----\n z  ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a^2}{b+c}", settings~)),
    " a²  \n-----\n b+c ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\dfrac{x}{y}", settings~)),
    " x \n---\n y ",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\binom{n}{k}", settings~)),
    "(n,k)",
  )
}

///|
test "render delimited block fraction aligned at fraction bar" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // \left( \frac{1}{2} \right): parens sit exactly on the fraction line
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left(\\frac{1}{2}\\right)", settings~),
    ),
    "  1  \n(---)\n  2  ",
  )
  // Other delimiter styles need no special-casing: single chars align the same
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left[\\frac{a}{bc}\\right]", settings~),
    ),
    "  a   \n[----]\n  bc  ",
  )
  // Asymmetric numerator/denominator — still anchored on the bar
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left(\\frac{x^2}{y+z}\\right)", settings~),
    ),
    "  x²   \n(-----)\n  y+z  ",
  )
  // \genfrac with a bar line and delimiters follows the same layout
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\genfrac{(}{)}{0.4pt}{1}{x}{y}", settings~),
    ),
    "  x  \n(---)\n  y  ",
  )
}

///|
test "render delimited block fraction inside expression" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("a+\\left(\\frac{1}{2}\\right)", settings~),
    ),
    "      1  \na + (---)\n      2  ",
  )
}

///|
test "render left-right delimiters inline in non-display mode" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left(\\frac{1}{2}\\right)")),
    "(1∕2)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left( x \\right)")),
    "(x)",
  )
}

///|
test "render fraction alignment extremes" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // Very wide numerator, very narrow denominator
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{aaaaaaa}{b}", settings~)),
    " aaaaaaa \n---------\n    b    ",
  )
  // Very narrow numerator, very wide denominator
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{bbbbbbb}", settings~)),
    "    a    \n---------\n bbbbbbb ",
  )
  // Equal width
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{aaa}{bbb}", settings~)),
    " aaa \n-----\n bbb ",
  )
}

///|
test "render fractions with configurable slash" {
  let config = @unicode.RenderConfig::make(fraction_slash="/")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{b}"), config~),
    "a/b",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a+b}{c+d}"), config~),
    "(a+b)/(c+d)",
  )
}
