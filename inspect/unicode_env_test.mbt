///|
test "render overline with compound body and underline" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\overline{xy}")),
    "overline(xy)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\underline{x}")),
    "underline(x)",
  )
}

///|
test "render left-right delimiters" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left( x \\right)")),
    "(x)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left[ x \\right]")),
    "[x]",
  )
}

///|
test "render font commands as Unicode math alphanumerics" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathbb{R}")), "ℝ")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathbf{x}")), "𝐱")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathit{x}")), "𝑥")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathsf{A}")), "𝖠")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathtt{x}")), "𝚡")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathcal{L}")), "ℒ")
}

///|
test "render additional font mappings" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathbb{1}")), "𝟙")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathbb{42}")), "𝟜𝟚")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathit{\\alpha}")), "𝛼")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathit{\\Gamma\\beta}")),
    "𝛤𝛽",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbf{\\nabla\\partial}")),
    "𝛁𝛛",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathit{\\nabla\\partial}")),
    "𝛻𝜕",
  )
  // \mathnormal maps to italic, \mathrm stays upright
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathnormal{x}")),
    "𝑥",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathnormal{\\alpha}")),
    "𝛼",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathrm{x}")), "x")
}

///|
test "render text and phantom" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\text{hello}")),
    "hello",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\phantom{xy}")),
    "phantom(xy)",
  )
}

///|
test "phantom family stays consistent" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\phantom{x}")), "phantom(x)")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\vphantom{x}")), "vphantom(x)")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\hphantom{x}")), "phantom(x)")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\vphantom{a+b}_1")),
    "vphantom(a + b)₁",
  )
}

///|
test "visible repositioned nodes stay transparent" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\smash{x}")), "x")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\raisebox{1pt}{x}")), "x")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathllap{x}")), "x")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\vcenter{x}")), "x")
}

///|
test "untrusted html commands render empty" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\href{a}{b}")), "")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\url{http://x}")), "")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\includegraphics{foo}")),
    "",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\htmlClass{foo}{x}")),
    "",
  )
  // Undefined control sequences still keep their name
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\nosuchcommand",
        settings=@katex_parser.Settings::make(throw_on_error=false),
      ),
    ),
    "\\nosuchcommand",
  )
}

///|
test "pass through color body" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\color{#abc}x")), "x")
}

///|
test "render verbatim text" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\verb|x|")), "x")
}

///|
test "render matrix environments" {
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}"),
    ),
    "(a, b; c, d)",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}"),
    ),
    "[a, b; c, d]",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\begin{matrix}a \\\\ b\\end{matrix}")),
    "a; b",
  )
}

///|
test "render matrix environments in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}",
        settings~,
      ),
    ),
    "(a  b)\n(c  d)",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}",
        settings~,
      ),
    ),
    "[a  b]\n[c  d]",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{matrix}a \\\\ b\\end{matrix}", settings~),
    ),
    "a\nb",
  )
}

///|
test "render matrix with uneven column widths in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}aa & b \\\\ c & ddd\\end{pmatrix}",
        settings~,
      ),
    ),
    "(aa  b  )\n(c   ddd)",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}",
        settings~,
      ),
    ),
    "(a  b)\n(c  d)",
  )
}

///|
test "render matrix with single column in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}a \\\\ b \\\\ c\\end{pmatrix}",
        settings~,
      ),
    ),
    "(a)\n(b)\n(c)",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{pmatrix}aa \\\\ b\\end{pmatrix}", settings~),
    ),
    "(aa)\n(b )",
  )
}
