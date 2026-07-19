///|
test "render Unicode symbols and scripts" {
  @test.assert_eq(
    render(@katex_parser.parse("\\alpha_2^n + \\beta")),
    "α₂ⁿ + β",
  )
}

///|
test "render structural nodes without losing information" {
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a}{b}+\\sqrt[3]{x}+\\overline y")),
    "a∕b + ³√x + overline(y)",
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
  @test.assert_eq(render(@katex_parser.parse("\\sqrt{x+y}")), "√(x + y)")
}

///|
test "preserve grouping for fraction and script operands" {
  @test.assert_eq(render(@katex_parser.parse("\\frac{a+b}{c}")), "(a+b)∕c")
  @test.assert_eq(render(@katex_parser.parse("{\\frac{a}{b}}^2")), "(a∕b)²")
}

///|
test "Font node treated as atomic for operand grouping" {
  @test.assert_eq(render(@katex_parser.parse("\\R_1")), "ℝ₁")
  @test.assert_eq(render(@katex_parser.parse("\\R^2")), "ℝ²")
  @test.assert_eq(render(@katex_parser.parse("\\R_1^2")), "ℝ₁²")
  @test.assert_eq(render(@katex_parser.parse("\\frac{\\R}{2}")), "ℝ∕2")
  // Font with unmappable body still atomic (self-delimiting notation)
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{\\mathbb{abc}}{2}")),
    "mathbb(abc)∕2",
  )
}

///|
test "Sqrt treated as atomic operand" {
  @test.assert_eq(render(@katex_parser.parse("\\sqrt{x}_1")), "√x₁")
  @test.assert_eq(render(@katex_parser.parse("\\sqrt{x}^2")), "√x²")
  @test.assert_eq(render(@katex_parser.parse("\\sqrt{x+y}_1")), "√(x + y)₁")
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{\\sqrt{x}}{y}")),
    "√x∕y",
  )
}

///|
test "Overline and Underline treated as atomic operands" {
  @test.assert_eq(
    render(@katex_parser.parse("\\overline{x}_1")),
    "overline(x)₁",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\underline{x}^2")),
    "underline(x)²",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{\\overline{a}}{b}")),
    "overline(a)∕b",
  )
}

///|
test "self-delimiting function notation stays atomic" {
  // Phantom: renders as phantom(body)
  @test.assert_eq(
    render(@katex_parser.parse("\\phantom{x}_1")),
    "phantom(x)₁",
  )
  // Enclose (via \cancel): renders as cancel(body)
  @test.assert_eq(
    render(@katex_parser.parse("\\cancel{x}_1")),
    "\\cancel(x)₁",
  )
  // Pmb: renders as bold(body)
  @test.assert_eq(render(@katex_parser.parse("\\pmb{x}_1")), "bold(x)₁")
  // Rule: renders as rule(w,h)
  @test.assert_eq(
    render(@katex_parser.parse("\\rule{1em}{2pt}_1")),
    "rule(1em,2pt)₁",
  )
  // Kern: renders as kern(dim)
  @test.assert_eq(render(@katex_parser.parse("\\kern{1em}_1")), "kern(1em)₁")
  // AccentUnder: renders as underaccent(cmd,body) (self-delimiting)
  @test.assert_eq(
    render(@katex_parser.parse("\\underleftarrow{x}_1")),
    "underaccent(\\underleftarrow,x)₁",
  )
}

///|
test "complex nodes with operators stay non-atomic" {
  // GenFrac contains / operator — needs parens
  @test.assert_eq(render(@katex_parser.parse("\\frac{a}{b}_1")), "(a∕b)₁")
}

///|
test "compound expression with non-atomic base still parenthesized" {
  @test.assert_eq(render(@katex_parser.parse("\\frac{a}{b}_1")), "(a∕b)₁")
  @test.assert_eq(render(@katex_parser.parse("{a+b}_1")), "(a + b)₁")
  @test.assert_eq(
    render(@katex_parser.parse("\\frac{a+b}{c+d}")),
    "(a+b)∕(c+d)",
  )
}

///|
test "nested atomic wrappers preserve atomicity" {
  @test.assert_eq(render(@katex_parser.parse("\\hat{x}_1")), "x̂₁")
  @test.assert_eq(render(@katex_parser.parse("\\hat{\\R}_1")), "ℝ̂₁")
  @test.assert_eq(render(@katex_parser.parse("\\bar{x}_1")), "x̄₁")
}

///|
test "single-char within text styling stays atomic" {
  @test.assert_eq(render(@katex_parser.parse("\\text{x}_1")), "x₁")
  @test.assert_eq(render(@katex_parser.parse("\\mathrm{x}_1")), "x₁")
  @test.assert_eq(render(@katex_parser.parse("\\textbf{x}_1")), "x₁")
}

///|
test "compound body inside styling is not atomic" {
  @test.assert_eq(render(@katex_parser.parse("\\text{ab}_1")), "(ab)₁")
  @test.assert_eq(render(@katex_parser.parse("\\text{a+b}_1")), "(a+b)₁")
}

///|
test "accent uses function notation for multi-character bases" {
  // Multi-char base — no combining mark
  @test.assert_eq(
    render(@katex_parser.parse("\\hat{\\overline{x}}")),
    "\\hat(overline(x))",
  )
  // LeftRight is multi-char — function notation
  @test.assert_eq(
    render(@katex_parser.parse("\\hat{\\left(x\\right)}")),
    "\\hat((x))",
  )
  // Single-char base still gets combining mark
  @test.assert_eq(render(@katex_parser.parse("\\hat{x}")), "x̂")
}

///|
test "render radicals with fractions and deep nesting" {
  @test.assert_eq(
    render(@katex_parser.parse("\\sqrt{\\frac{a}{b}}")),
    "√(a∕b)",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\sqrt[3]{\\frac{a}{b}}")),
    "³√(a∕b)",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\sqrt{\\frac{\\frac{a}{b}}{c}}")),
    "√((a∕b)∕c)",
  )
}

///|
test "toplevel infix operator spacing" {
  @test.assert_eq(
    render(
      @katex_parser.parse("\\R_{\\ge 0}^* = \\R_{\\ge 0} \\cup \\{\\infty\\}"),
    ),
    "ℝ_(≥0)^∗ = ℝ_(≥0) ∪ {∞}",
  )
}

///|
test "TeX spacing around infix operators" {
  // Binary operators get spacing
  @test.assert_eq(render(@katex_parser.parse("a + b")), "a + b")
  // Relation operators get spacing
  @test.assert_eq(render(@katex_parser.parse("a = b")), "a = b")
  // No spacing inside subscripts (tight mode)
  @test.assert_eq(render(@katex_parser.parse("x_{a+b}")), "x_(a+b)")
  // No spacing inside superscripts (tight mode)
  @test.assert_eq(render(@katex_parser.parse("x^{a+b}")), "xᵃ⁺ᵇ")
  // Bin at start of group becomes ord (no left spacing)
  @test.assert_eq(render(@katex_parser.parse("{+x}")), "+x")
  // Multiple operators: spacing between each
  @test.assert_eq(
    render(@katex_parser.parse("a + b = c \\cup d")),
    "a + b = c ∪ d",
  )
}
