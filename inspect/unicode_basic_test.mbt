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
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathbb{42}")),
    "𝟜𝟚",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathit{\\alpha}")),
    "𝛼",
  )
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
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\phantom{x}")),
    "phantom(x)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\vphantom{x}")),
    "vphantom(x)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\hphantom{x}")),
    "phantom(x)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\vphantom{a+b}_1")),
    "vphantom(a + b)₁",
  )
}

///|
test "visible repositioned nodes stay transparent" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\smash{x}")), "x")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\raisebox{1pt}{x}")),
    "x",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathllap{x}")), "x")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\vcenter{x}")), "x")
}

///|
test "untrusted html commands keep visible text" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\href{a}{b}")), "b")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\url{http://x}")),
    "http://x",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\includegraphics{img.png}")),
    "img",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\htmlClass{foo}{x}")),
    "x",
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
test "render hbox transparently" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\hbox{ab}")), "ab")
}

///|
test "render sizing delimiters" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\big( x \\big)")),
    "(x)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\bigl[ x \\bigr]")),
    "[x]",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\Bigg\\{ x \\Bigg\\}")),
    "{x}",
  )
}

///|
test "render middle delimiter" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left( x \\middle| y \\right)")),
    "(x ∣ y)",
  )
}

///|
test "render explicit math classes" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("a \\mathbin{+} b")),
    "a + b",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("a \\mathrel{=} b")),
    "a = b",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathop{x}")), "x")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathopen{(}a\\mathclose{)}")),
    "(a)",
  )
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathpunct{,}b")), ", b")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\mathinner{a}")), "a")
}

///|
test "render fallback decorations" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\textcircled{a}")),
    "textcircled(a)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\mathstrut")),
    "vphantom(()",
  )
}
