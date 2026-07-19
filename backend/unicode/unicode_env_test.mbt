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
test "render matrix environments" {
  @test.assert_eq(
    render(
      @katex_parser.parse("\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}"),
    ),
    "(a, b; c, d)",
  )
  @test.assert_eq(
    render(
      @katex_parser.parse("\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}"),
    ),
    "[a, b; c, d]",
  )
  @test.assert_eq(
    render(@katex_parser.parse("\\begin{matrix}a \\\\ b\\end{matrix}")),
    "a; b",
  )
}

///|
test "render matrix environments in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    render(
      @katex_parser.parse(
        "\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}",
        settings~,
      ),
    ),
    "(a  b)\n(c  d)",
  )
  @test.assert_eq(
    render(
      @katex_parser.parse(
        "\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}",
        settings~,
      ),
    ),
    "[a  b]\n[c  d]",
  )
  @test.assert_eq(
    render(
      @katex_parser.parse("\\begin{matrix}a \\\\ b\\end{matrix}", settings~),
    ),
    "a\nb",
  )
}
