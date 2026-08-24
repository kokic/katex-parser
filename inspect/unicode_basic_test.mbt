///|
test "render overline with compound body and underline" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\overline{xy}")),
    "overline(xy)",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\underline{x}")),
    "underline(x)",
  )
}

///|
test "render left-right delimiters" {
  @test.assert_eq(@unicode.render(@katex.parse("\\left( x \\right)")), "(x)")
  @test.assert_eq(@unicode.render(@katex.parse("\\left[ x \\right]")), "[x]")
}

///|
test "render font commands as Unicode math alphanumerics" {
  @test.assert_eq(@unicode.render(@katex.parse("\\mathbb{R}")), "ℝ")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathbf{x}")), "𝐱")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathit{x}")), "𝑥")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathsf{A}")), "𝖠")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathtt{x}")), "𝚡")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathcal{L}")), "ℒ")
}

///|
test "render additional font mappings" {
  @test.assert_eq(@unicode.render(@katex.parse("\\mathbb{1}")), "𝟙")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathbb{42}")), "𝟜𝟚")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathit{\\alpha}")), "𝛼")
  @test.assert_eq(
    @unicode.render(@katex.parse("\\mathit{\\Gamma\\beta}")),
    "𝛤𝛽",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\mathbf{\\nabla\\partial}")),
    "𝛁𝛛",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\mathit{\\nabla\\partial}")),
    "𝛻𝜕",
  )
  // \mathnormal maps to italic, \mathrm stays upright
  @test.assert_eq(@unicode.render(@katex.parse("\\mathnormal{x}")), "𝑥")
  @test.assert_eq(
    @unicode.render(@katex.parse("\\mathnormal{\\alpha}")),
    "𝛼",
  )
  @test.assert_eq(@unicode.render(@katex.parse("\\mathrm{x}")), "x")
}

///|
test "render text and phantom" {
  @test.assert_eq(@unicode.render(@katex.parse("\\text{hello}")), "hello")
  @test.assert_eq(@unicode.render(@katex.parse("\\phantom{xy}")), "phantom(xy)")
}

///|
test "phantom family stays consistent" {
  @test.assert_eq(@unicode.render(@katex.parse("\\phantom{x}")), "phantom(x)")
  @test.assert_eq(@unicode.render(@katex.parse("\\vphantom{x}")), "vphantom(x)")
  @test.assert_eq(@unicode.render(@katex.parse("\\hphantom{x}")), "phantom(x)")
  @test.assert_eq(
    @unicode.render(@katex.parse("\\vphantom{a+b}_1")),
    "vphantom(a + b)₁",
  )
}

///|
test "visible repositioned nodes stay transparent" {
  @test.assert_eq(@unicode.render(@katex.parse("\\smash{x}")), "x")
  @test.assert_eq(@unicode.render(@katex.parse("\\raisebox{1pt}{x}")), "x")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathllap{x}")), "x")
  @test.assert_eq(@unicode.render(@katex.parse("\\vcenter{x}")), "x")
}

///|
test "untrusted html commands keep visible text" {
  @test.assert_eq(@unicode.render(@katex.parse("\\href{a}{b}")), "b")
  @test.assert_eq(@unicode.render(@katex.parse("\\url{http://x}")), "http://x")
  @test.assert_eq(
    @unicode.render(@katex.parse("\\includegraphics{img.png}")),
    "img",
  )
  @test.assert_eq(@unicode.render(@katex.parse("\\htmlClass{foo}{x}")), "x")
  // Undefined control sequences still keep their name
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\nosuchcommand",
        settings=@katex.Settings::make(throw_on_error=false),
      ),
    ),
    "\\nosuchcommand",
  )
}

///|
test "pass through color body" {
  @test.assert_eq(@unicode.render(@katex.parse("\\color{#abc}x")), "x")
}

///|
test "render verbatim text" {
  @test.assert_eq(@unicode.render(@katex.parse("\\verb|x|")), "x")
}

///|
test "render hbox transparently" {
  @test.assert_eq(@unicode.render(@katex.parse("\\hbox{ab}")), "ab")
}

///|
test "render sizing delimiters" {
  @test.assert_eq(@unicode.render(@katex.parse("\\big( x \\big)")), "(x)")
  @test.assert_eq(@unicode.render(@katex.parse("\\bigl[ x \\bigr]")), "[x]")
  @test.assert_eq(@unicode.render(@katex.parse("\\Bigg\\{ x \\Bigg\\}")), "{x}")
}

///|
test "render middle delimiter" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\left( x \\middle| y \\right)")),
    "(x ∣ y)",
  )
}

///|
test "render explicit math classes" {
  @test.assert_eq(@unicode.render(@katex.parse("a \\mathbin{+} b")), "a + b")
  @test.assert_eq(@unicode.render(@katex.parse("a \\mathrel{=} b")), "a = b")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathop{x}")), "x")
  @test.assert_eq(
    @unicode.render(@katex.parse("\\mathopen{(}a\\mathclose{)}")),
    "(a)",
  )
  @test.assert_eq(@unicode.render(@katex.parse("\\mathpunct{,}b")), ", b")
  @test.assert_eq(@unicode.render(@katex.parse("\\mathinner{a}")), "a")
}

///|
test "render fallback decorations" {
  @test.assert_eq(
    @unicode.render(@katex.parse("\\textcircled{a}")),
    "textcircled(a)",
  )
  @test.assert_eq(@unicode.render(@katex.parse("\\mathstrut")), "vphantom(()")
}
