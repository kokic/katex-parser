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
test "render cases variants" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // dcases keeps the left brace, rcases/drcases the right brace.
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{dcases}a & b \\end{dcases}", settings~),
    ),
    "{a  b",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{rcases}a & b \\end{rcases}", settings~),
    ),
    "a  b}",
  )
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{drcases}a & b \\end{drcases}", settings~),
    ),
    "a  b}",
  )
}

///|
test "render array inline without display mode" {
  // Outside display mode arrays flatten to rows separated by `; ` with cells
  // joined by `, `.
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\begin{array}{cc}a & b \\\\ c & d\\end{array}"),
    ),
    "a, b; c, d",
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
test "render subarray and substack" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // subarray stacks rows as a single-column array; \substack is its macro.
  let output =
    #|a
    #|b
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{subarray}{l} a \\\\ b \\end{subarray}",
        settings~,
      ),
    ),
    output,
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\substack{a \\\\ b}", settings~)),
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
