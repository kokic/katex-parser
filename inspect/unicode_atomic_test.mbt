///|
test "preserve grouping for fraction and script operands" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a+b}{c}")),
    "(a+b)∕c",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("{\\frac{a}{b}}^2")),
    "(a∕b)²",
  )
}

///|
test "Sqrt treated as atomic operand" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\sqrt{x}_1")),
    "√x₁",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\sqrt{x}^2")), "√x²")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\sqrt{x+y}_1")),
    "√(x + y)₁",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{\\sqrt{x}}{y}")),
    "√x∕y",
  )
}

///|
test "Overline and Underline treated as atomic operands" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\overline{x}_1")),
    "overline(x)₁",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\underline{x}^2")),
    "underline(x)²",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{\\overline{a}}{b}")),
    "overline(a)∕b",
  )
}

///|
test "self-delimiting function notation stays atomic" {
  // Phantom: renders as phantom(body)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\phantom{x}_1")),
    "phantom(x)₁",
  )
  // Enclose (via \cancel): renders as cancel(body)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\cancel{x}_1")),
    "cancel(x)₁",
  )
  // Pmb: renders as bold(body)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\pmb{x}_1")),
    "bold(x)₁",
  )
  // Rule: renders as rule(w,h)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\rule{1em}{2pt}_1")),
    "rule(1em,2pt)₁",
  )
  // Kern: renders as kern(dim) for non-space units
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\kern{1pt}_1")),
    "kern(1pt)₁",
  )
  // AccentUnder: renders as underaccent(cmd,body) (self-delimiting)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\underleftarrow{x}_1")),
    "underaccent(underleftarrow,x)₁",
  )
}

///|
test "complex nodes with operators stay non-atomic" {
  // GenFrac contains / operator — needs parens
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{b}_1")),
    "(a∕b)₁",
  )
}

///|
test "compound expression with non-atomic base still parenthesized" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{b}_1")),
    "(a∕b)₁",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("{a+b}_1")), "(a + b)₁")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a+b}{c+d}")),
    "(a+b)∕(c+d)",
  )
}

///|
test "nested atomic wrappers preserve atomicity" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\hat{x}_1")), "x̂₁")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\hat{\\R}_1")),
    "ℝ̂₁",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\bar{x}_1")), "x̄₁")
}

///|
test "single-char within text styling stays atomic" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\text{x}_1")), "x₁")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathrm{x}_1")), "x₁")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\textbf{x}_1")), "x₁")
}

///|
test "compound body inside styling is not atomic" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\text{ab}_1")),
    "(ab)₁",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\text{a+b}_1")),
    "(a+b)₁",
  )
}

///|
test "block content in scripts renders inline" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // Fractions in scripts stay on one line rather than misaligning a block
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("x^{\\frac{a}{b}}", settings~)),
    "x^(a∕b)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("x_{\\frac{a}{b}}", settings~)),
    "x_(a∕b)",
  )
}

///|
test "mathchoice selects variant by current style" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("a\\mathchoice{D}{T}{S}{SS}b")),
    "aTb",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("a\\textstyle\\mathchoice{D}{T}{S}{SS}b"),
    ),
    "aTb",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("a\\displaystyle\\mathchoice{D}{T}{S}{SS}b"),
    ),
    "aDb",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("a\\scriptstyle\\mathchoice{D}{T}{S}{SS}b"),
    ),
    "aSb",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("a\\scriptscriptstyle\\mathchoice{D}{T}{S}{SS}b"),
    ),
    "aSSb",
  )
}

///|
test "fallback function notation aligns around block fractions" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|          a  
    #|overline(───)
    #|          b  
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\overline{\\frac{a}{b}}", settings~)),
    output,
  )
}
