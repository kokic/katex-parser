///|
test "render matrix environments inline" {
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}"),
    ),
    "(a, b; c, d)",
  )
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}"),
    ),
    "[a, b; c, d]",
  )
  @test.assert_eq(
    @unicode.render(@katex.parse("\\begin{matrix}a \\\\ b\\end{matrix}")),
    "a; b",
  )
}

///|
test "render matrix environments in block mode" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|(a  b)
    #|(c  d)
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}", settings~),
    ),
    output,
  )
  let output =
    #|[a  b]
    #|[c  d]
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{bmatrix}a & b \\\\ c & d\\end{bmatrix}", settings~),
    ),
    output,
  )
  let output =
    #|a
    #|b
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{matrix}a \\\\ b\\end{matrix}", settings~),
    ),
    output,
  )
}

///|
test "render matrix with uneven column widths in block mode" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|(aa  b  )
    #|(c   ddd)
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
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
      @katex.parse("\\begin{pmatrix}a & b \\\\ c & d\\end{pmatrix}", settings~),
    ),
    output,
  )
}

///|
test "render matrix with single column in block mode" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|(a)
    #|(b)
    #|(c)
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{pmatrix}a \\\\ b \\\\ c\\end{pmatrix}", settings~),
    ),
    output,
  )
  let output =
    #|(aa)
    #|(b )
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{pmatrix}aa \\\\ b\\end{pmatrix}", settings~),
    ),
    output,
  )
}

///|
test "trailing backslash in matrix does not add a blank row" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|a
    #|b
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{matrix} a \\\\ b \\\\ \\end{matrix}", settings~),
    ),
    output,
  )
}

///|
test "render delimited matrix variants in block mode" {
  let settings = @katex.Settings::make(display_mode=true)
  // vmatrix, Vmatrix and Bmatrix use their own delimiter pairs.
  let output =
    #|∣a  b∣
    #|∣c  d∣
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{vmatrix}a & b \\\\ c & d\\end{vmatrix}", settings~),
    ),
    output,
  )
  let output =
    #|‖a  b‖
    #|‖c  d‖
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{Vmatrix}a & b \\\\ c & d\\end{Vmatrix}", settings~),
    ),
    output,
  )
  let output =
    #|{a  b}
    #|{c  d}
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{Bmatrix}a & b \\\\ c & d\\end{Bmatrix}", settings~),
    ),
    output,
  )
}

///|
test "render matrix star environment with explicit alignment" {
  let settings = @katex.Settings::make(display_mode=true)
  // `[r]` right-aligns the first column, `[l]` the default center is unused.
  let output =
    #|a   b
    #|cc  d
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{matrix*}[r]a & b \\\\ cc & d\\end{matrix*}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "render smallmatrix in block mode" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|a  b
    #|c  d
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{smallmatrix}a & b \\\\ c & d\\end{smallmatrix}",
        settings~,
      ),
    ),
    output,
  )
}
