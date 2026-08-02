///|
test "render 2x2 commutative diagram" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let source =
    #|\begin{CD}
    #|   A @>a>> B \\
    #|@VbVV @AAcA \\
    #|   C @= D
    #|\end{CD}

  let output =
    #|    a     
    #| A ───→ B 
    #| │      ↑ 
    #|b│      │c
    #| ↓      │ 
    #| C ==== D 
  @test.assert_eq(@unicode.render(@katex_parser.parse(source, settings~)), output)
}

///|
test "render single-row commutative diagram" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|   a    
    #|A ───→ B
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\begin{CD} A @>a>> B \\end{CD}", settings~)),
    output,
  )
}

///|
test "render 3x3 commutative diagram" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let source =
    #|\begin{CD}
    #|   A @>a>> B @>c>> C \\
    #|@VdVV @VeVV @AAfA \\
    #|   D @= E @= F
    #|\end{CD}

  let output =
    #|     a      c     
    #| A ────→ B ───→ C 
    #| │       │      ↑ 
    #|d│      e│      │f
    #| ↓       ↓      │ 
    #| D ===== E ==== F 
  @test.assert_eq(@unicode.render(@katex_parser.parse(source, settings~)), output)
}

///|
test "render commutative diagram with lower arrow label" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|A ───→ B
    #|   b    
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\begin{CD} A @>>b>B \\end{CD}", settings~)),
    output,
  )
}

///|
test "render commutative diagram with upper and lower arrow labels" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|   a    
    #|A ───→ B
    #|   b    
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\begin{CD} A @>a>b>B \\end{CD}", settings~)),
    output,
  )
}

///|
test "render left arrow and vert bar arrows" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|   a    
    #|A ←─── B
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\begin{CD} A @<a<< B \\end{CD}", settings~)),
    output,
  )
  let output =
    #|A ‖    B
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\begin{CD} A @| B \\end{CD}", settings~)),
    output,
  )
}

///|
test "render commutative diagram with left and right v-arrow labels" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|     a     
    #| A  ───→ B 
    #| │       ↑ 
    #|b│c      │e
    #| ↓       │ 
    #| C  ==== D 
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse(
        "\\begin{CD} A @>a>> B \\\\ @VbVcV @AAeAfA \\\\ C @= D \\end{CD}",
        settings~,
      ),
    ),
    output,
  )
}

///|
test "render commutative diagram in ascii line style" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let config = @unicode.RenderConfig::make(line_style=@unicode.LineStyle::Ascii)
  let source =
    #|\begin{CD} A @>a>> B \\ @VbVV @AAcA \\ C @= D \end{CD}
  let output =
    #|    a     
    #| A ---→ B 
    #| |      ↑ 
    #|b|      |c
    #| ↓      | 
    #| C ==== D 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse(source, settings~), config~),
    output,
  )
}
