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

///|
test "render superscript and subscript variants" {
  @test.assert_eq(render(@katex_parser.parse("x^{12}")), "x¹²")
  @test.assert_eq(render(@katex_parser.parse("x_{ij}")), "xᵢⱼ")
}

///|
test "render all combining accent commands" {
  @test.assert_eq(render(@katex_parser.parse("\\acute{x}")), "x́")
  @test.assert_eq(render(@katex_parser.parse("\\grave{x}")), "x̀")
  @test.assert_eq(render(@katex_parser.parse("\\ddot{x}")), "ẍ")
  @test.assert_eq(render(@katex_parser.parse("\\tilde{x}")), "x̃")
  @test.assert_eq(render(@katex_parser.parse("\\bar{x}")), "x̄")
  @test.assert_eq(render(@katex_parser.parse("\\breve{x}")), "x̆")
  @test.assert_eq(render(@katex_parser.parse("\\check{x}")), "x̌")
  @test.assert_eq(render(@katex_parser.parse("\\dot{x}")), "ẋ")
  @test.assert_eq(render(@katex_parser.parse("\\mathring{x}")), "x̊")
  @test.assert_eq(render(@katex_parser.parse("\\vec{x}")), "x⃗")
}

///|
test "render binomial without fraction bar" {
  @test.assert_eq(render(@katex_parser.parse("\\binom{n}{k}")), "(n,k)")
}

///|
test "render overline with compound body and underline" {
  @test.assert_eq(render(@katex_parser.parse("\\overline{xy}")), "overline(xy)")
  @test.assert_eq(render(@katex_parser.parse("\\underline{x}")), "underline(x)")
}

///|
test "render left-right delimiters" {
  @test.assert_eq(render(@katex_parser.parse("\\left( x \\right)")), "(x)")
  @test.assert_eq(render(@katex_parser.parse("\\left[ x \\right]")), "[x]")
}

///|
test "render font commands as Unicode math alphanumerics" {
  @test.assert_eq(render(@katex_parser.parse("\\mathbb{R}")), "ℝ")
  @test.assert_eq(render(@katex_parser.parse("\\mathbf{x}")), "𝐱")
  @test.assert_eq(render(@katex_parser.parse("\\mathit{x}")), "𝑥")
  @test.assert_eq(render(@katex_parser.parse("\\mathsf{A}")), "𝖠")
  @test.assert_eq(render(@katex_parser.parse("\\mathtt{x}")), "𝚡")
  @test.assert_eq(render(@katex_parser.parse("\\mathcal{L}")), "ℒ")
}

///|
test "render text and phantom" {
  @test.assert_eq(render(@katex_parser.parse("\\text{hello}")), "hello")
  @test.assert_eq(render(@katex_parser.parse("\\phantom{xy}")), "phantom(xy)")
}

///|
test "pass through color body" {
  @test.assert_eq(render(@katex_parser.parse("\\color{#abc}x")), "x")
}

///|
test "render verbatim text" {
  @test.assert_eq(render(@katex_parser.parse("\\verb|x|")), "x")
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
test "render superscript and subscript with compound expressions" {
  @test.assert_eq(render(@katex_parser.parse("x^{a+b}")), "xᵃ⁺ᵇ")
  @test.assert_eq(render(@katex_parser.parse("x_{i+j}")), "xᵢ₊ⱼ")
  @test.assert_eq(render(@katex_parser.parse("x^2_n")), "xₙ²")
  @test.assert_eq(render(@katex_parser.parse("x_i^j")), "xᵢʲ")
}

///|
test "render matrix environments" {
  @test.assert_eq(
    render(@katex_parser.parse("\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}")),
    "(a, b; c, d)",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}")),
    "[a, b; c, d]",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\begin{matrix}a \\\\ b\\end{matrix}")),
    "a; b",
  )
}
