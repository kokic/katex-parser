///|
test "render Unicode symbols and scripts" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\alpha_2^n + \\beta")),
    "α₂ⁿ + β",
  )
}

///|
test "render operators, symbols, and spacing to Unicode" {
  let source =
    #|\chi(X, E) = \int_X \operatorname{ch}(E) \cdot \operatorname{td}(T_X)
  @test.assert_eq(
    @unicode.render(@katex.parse(source)),
    "χ(X, E) = ∫_X ch(E) ⋅ td(T_X)",
  )
}

///|
test "render structural nodes without losing information" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\frac{a}{b}+\\sqrt[3]{x}+\\overline y")),
    "a∕b + ³√x + overline(y)",
  )
}

///|
test "overlay \\not onto the following symbol" {
  @test.assert_eq(@unicode.render(@katex.parse("\\not=")), "≠")
  @test.assert_eq(@unicode.render(@katex.parse("\\not<")), "≮")
  @test.assert_eq(@unicode.render(@katex.parse("\\not\\in")), "∉")
  @test.assert_eq(@unicode.render(@katex.parse("\\not x")), "x̸")
  @test.assert_eq(@unicode.render(@katex.parse("a\\not=b")), "a ≠ b")
  // Predefined negated relations render as single characters
  @test.assert_eq(@unicode.render(@katex.parse("\\neq")), "≠")
  @test.assert_eq(@unicode.render(@katex.parse("\\notin")), "∉")
}

///|
test "use UnicodeMath syntax for unsupported scripts" {
  @test.assert_eq(@unicode.render(@katex.parse("x^{q}")), "x^q")
}

///|
test "retain non-Unicode root indices as UnicodeMath" {
  @test.assert_eq(@unicode.render(@katex.parse("\\sqrt[q]{x}")), "root(q,x)")
}

///|
test "parenthesize compound radical bodies" {
  @test.assert_eq(@unicode.render(@katex.parse("\\sqrt{x}")), "√x")
  @test.assert_eq(@unicode.render(@katex.parse("\\sqrt{x+y}")), "√(x + y)")
}

///|
test "render radicals with fractions and deep nesting" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\sqrt{\\frac{a}{b}}")),
    "√(a∕b)",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\sqrt[3]{\\frac{a}{b}}")),
    "³√(a∕b)",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\sqrt{\\frac{\\frac{a}{b}}{c}}")),
    "√((a∕b)∕c)",
  )
}

///|
test "radical aligns with block fractions in display mode" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|   πe  
    #|√(────)
    #|   2   
  @test.assert_eq(
    @unicode.render(@katex.parse("\\sqrt{\\frac{\\pi e}{2}}", settings~)),
    output,
  )
  // A radical as a sibling of other atoms shares the fraction-bar baseline
  let output =
    #|       a  
    #|x + √(───)
    #|       b  
  @test.assert_eq(
    @unicode.render(@katex.parse("x + \\sqrt{\\frac{a}{b}}", settings~)),
    output,
  )
}
