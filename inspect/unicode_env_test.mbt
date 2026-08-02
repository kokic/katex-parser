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
  let output =
    #|(a  b)
    #|(c  d)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}",
        settings~,
      ),
    ),
    output,
  )
  let output =
    #|[a  b]
    #|[c  d]
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}",
        settings~,
      ),
    ),
    output,
  )
  let output =
    #|a
    #|b
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{matrix}a \\\\ b\\end{matrix}", settings~),
    ),
    output,
  )
}

///|
test "render matrix with uneven column widths in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|(aa  b  )
    #|(c   ddd)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}aa & b \\\\ c & ddd\\end{pmatrix}",
        settings~,
      ),
    ),
    output,
  )
  let output =
    #|(a  b)
    #|(c  d)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "render matrix with single column in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|(a)
    #|(b)
    #|(c)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}a \\\\ b \\\\ c\\end{pmatrix}",
        settings~,
      ),
    ),
    output,
  )
  let output =
    #|(aa)
    #|(b )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{pmatrix}aa \\\\ b\\end{pmatrix}", settings~),
    ),
    output,
  )
}

///|
test "render cases with null right delimiter" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // \right. is the null delimiter: no trailing delimiter may appear.
  // The space inside \text{if } maps to NBSP (U+00A0), matching KaTeX.
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{cases} a & \\text{if } b \\\\ \\\\ c & \\text{if } d\\end{cases}",
        settings~,
      ),
    ),
    "{a  if\u{A0}b\n{       \n{c  if\u{A0}d",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left\\{ x \\right.", settings~)),
    "{x",
  )
}

///|
test "array grid lines render in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // `|c|c|` vertical bars and `\hline` rules are drawn with box-drawing
  // glyphs; the rule before the first row forms the top border, the one
  // between rows a middle rule.
  let output =
    #|┌──┬──┐
    #|│a │ b│
    #|├──┼──┤
    #|│c │ d│
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{array}{|c|c|} \\hline a & b \\\\ \\hline c & d\\end{array}",
        settings~,
      ),
    ),
    output,
  )
  // ASCII line style uses `-`/`|`/`+` instead.
  let config = @unicode.RenderConfig::make(line_style=@unicode.LineStyle::Ascii)
  let ascii =
    #|+--+--+
    #||a | b|
    #|+--+--+
    #||c | d|
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{array}{|c|c|} \\hline a & b \\\\ \\hline c & d\\end{array}",
        settings~,
      ),
      config~,
    ),
    ascii,
  )
}

///|
test "trailing hline keeps a bottom border in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // A trailing `\\ \hline` produces an empty final row that is dropped, but
  // its rule is kept as the bottom border.
  let output =
    #|│a │ b│
    #|├──┼──┤
    #|│c │ d│
    #|└──┴──┘
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{array}{|c|c|} a & b \\\\ \\hline c & d \\\\ \\hline\\end{array}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "dashed separators and hlines in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // `:` is a dashed vertical separator; `\hdashline` is a dashed rule.
  let output =
    #|┌┄┄┬┄┄┐
    #|│a ┊ b│
    #|├┄┄┼┄┄┤
    #|│c ┊ d│
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{array}{|c:c|} \\hdashline a & b \\\\ \\hdashline c & d\\end{array}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "block array alignment accounts for display width" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // Column widths are measured by display width, so astral-plane math
  // alphanumerics (screen width 1) and full-width CJK characters both align
  // with half-width content.
  let astral =
    #|(𝟙   x )
    #|(aa  yy)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}𝟙 & x \\\\ aa & yy\\end{pmatrix}",
        settings~,
      ),
    ),
    astral,
  )
  let cjk =
    #|(中  b)
    #|(aa  c)
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{pmatrix}\\text{中} & b \\\\ aa & c\\end{pmatrix}",
        settings~,
      ),
    ),
    cjk,
  )
}

///|
test "single-column array grid in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|┌─┐
    #|│a│
    #|│b│
    #|└─┘
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{array}{|c|} \\hline a \\\\ b \\\\ \\hline\\end{array}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "ragged rows keep grid cells padded in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|┌──┬───┐
    #|│a │ bb│
    #|│c │   │
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{array}{|c|c|} \\hline a & bb \\\\ c \\end{array}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "trailing backslash in matrix does not add a blank row" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|a
    #|b
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{matrix} a \\\\ b \\\\ \\end{matrix}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "array axis centered in display mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // x = centers against the middle (blank) row of the cases block
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "x = \\begin{cases}\n   a &\\text{if } b \\\\ \\\\\n   c &\\text{if } d\n\\end{cases}",
        settings~,
      ),
    ),
    "    {a  if\u{A0}b\nx = {       \n    {c  if\u{A0}d",
  )
  // Odd row count: label aligns with the exact middle row
  let output =
    #|    {x  p
    #|y = {z  q
    #|    {w  r
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "y = \\begin{cases} x & p \\\\ z & q \\\\ w & r \\end{cases}",
        settings~,
      ),
    ),
    output,
  )
}
