///|
test "render aligned environment aligned at relation" {
  let settings = @katex.Settings::make(display_mode=true)
  // The `&` is the alignment point: the left column is right-aligned so all
  // `=` signs line up, with the row spacing supplied by the alignment cell.
  let output =
    #|   a = b
    #|cccc = d
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{aligned}a &= b \\\\ cccc &= d\\end{aligned}",
        settings~,
      ),
    ),
    output,
  )
  // A row without `&` sits entirely in the left column, ending at the point.
  let output =
    #|logᵩ √5 − 1    
    #|            = 1
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{aligned}\\log_{\\phi}\\sqrt5-1 \\\\ &= 1\\end{aligned}",
        settings~,
      ),
    ),
    output,
  )
  // split uses the same alignment but without tag spacing
  let output =
    #|a = b
    #|c = d
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{split}a &= b \\\\ c &= d\\end{split}", settings~),
    ),
    output,
  )
}

///|
test "render aligned multiple alignment groups" {
  let settings = @katex.Settings::make(display_mode=true)
  // Every odd column boundary carries a 1em gap, the even ones none, so the
  // second group is offset while each `&` column still lines up.
  let output =
    #|   a = b  c = d
    #|eeee = f  g = h
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{aligned}a &= b & c &= d \\\\ eeee &= f & g &= h\\end{aligned}",
        settings~,
      ),
    ),
    output,
  )
  // alignat has no inter-column gaps; spacing comes from the source.
  let output =
    #| a = b c = d
    #|ee = fgg = h
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{alignedat}{2}a &= b & c &= d \\\\ ee &= f & gg &= h\\end{alignedat}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "render aligned with block fraction cells" {
  let settings = @katex.Settings::make(display_mode=true)
  // Multi-line cells (block fractions) define the real column width; the row
  // label aligns with the fraction bar instead of breaking the layout.
  let output =
    #|     1 
    #|x = ───
    #|     2 
    #|y = z  
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{aligned}x &= \\dfrac{1}{2} \\\\ y &= z\\end{aligned}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "render gathered centered with side margins" {
  let settings = @katex.Settings::make(display_mode=true)
  // gather/gathered center every row across the display width. With no viewer
  // width the block is sized as the widest row plus four spaces on each side.
  let output =
    #|      x      
    #|    y + 2    
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{gathered}x \\\\ y + 2\\end{gathered}", settings~),
    ),
    output,
  )
  let output =
    #|      x      
    #|    yyyyy    
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{gathered}x \\\\ yyyyy\\end{gathered}", settings~),
    ),
    output,
  )
}

///|
test "render align environments in display mode" {
  let settings = @katex.Settings::make(display_mode=true)
  // align (with automatic tags) and align* share the same alignment layout.
  let output =
    #|a = b
    #|c = d
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{align}a &= b \\\\ c &= d\\end{align}", settings~),
    ),
    output,
  )
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{align*}a &= b \\\\ c &= d\\end{align*}", settings~),
    ),
    output,
  )
}

///|
test "render alignat environments in display mode" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|a = bc = d
    #|e = fg = h
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{alignat}{2}a &= b & c &= d \\\\ e &= f & g &= h\\end{alignat}",
        settings~,
      ),
    ),
    output,
  )
  @test.assert_eq(
    @unicode.render(
      @katex.parse(
        "\\begin{alignat*}{2}a &= b & c &= d \\\\ e &= f & g &= h\\end{alignat*}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "render gather and equation environments" {
  let settings = @katex.Settings::make(display_mode=true)
  // gather centers every row with the four-space margin, exactly like
  // gathered; equation keeps its body inline.
  let output =
    #|    a    
    #|    b    
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{gather}a \\\\ b\\end{gather}", settings~),
    ),
    output,
  )
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{gather*}a \\\\ b\\end{gather*}", settings~),
    ),
    output,
  )
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{equation}x\\end{equation}", settings~),
    ),
    "x",
  )
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\begin{equation*}x\\end{equation*}", settings~),
    ),
    "x",
  )
}

///|
test "render tag macro" {
  let settings = @katex.Settings::make(display_mode=true)
  // \tag attaches a label after a tab.
  @test.assert_eq(
    @unicode.render(@katex.parse("\\tag{a} x", settings~)),
    "x\t(a)",
  )
}

///|
test "render overset and underset as stacked blocks" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|ab
    #|c 
  @test.assert_eq(
    @unicode.render(@katex.parse("\\overset{ab}{c}", settings~)),
    output,
  )
  let output =
    #|c 
    #|ab
  @test.assert_eq(
    @unicode.render(@katex.parse("\\underset{ab}{c}", settings~)),
    output,
  )
}
