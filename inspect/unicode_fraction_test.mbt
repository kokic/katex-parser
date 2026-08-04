///|
test "render deep cfrac with baseline alignment" {
  let source =
    #|\frac{p}{q}=a_0+\cfrac{1}{a_1+\cfrac{1}{a_2+\cfrac{1}{a_3}}}

  let output =
    #| p                 1         
    #|─── = a₀ + ──────────────────
    #| q                    1      
    #|            a₁ + ─────────── 
    #|                        1    
    #|                  a₂ + ────  
    #|                        a₃   

  let settings = @katex_parser.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse(source, settings~)),
    output,
  )
}

///|
test "render binomial without fraction bar" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\binom{n}{k}")),
    "(n,k)",
  )
}

///|
test "render nested fractions" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{\\frac{a}{b}}{c}")),
    "(a∕b)∕c",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{\\frac{b}{c}}")),
    "a∕(b∕c)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a+b}{c+d}")),
    "(a+b)∕(c+d)",
  )
}

///|
test "render fractions in block mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #| a 
    #|───
    #| b 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{b}", settings~)),
    output,
  )
  let output =
    #| a  
    #|────
    #| bc 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{bc}", settings~)),
    output,
  )
  let output =
    #| xy 
    #|────
    #| z  
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{xy}{z}", settings~)),
    output,
  )
  let output =
    #|  a²   
    #|───────
    #| b + c 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a^2}{b+c}", settings~)),
    output,
  )
  let output =
    #| x 
    #|───
    #| y 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\dfrac{x}{y}", settings~)),
    output,
  )
  let output =
    #|(n)
    #|(k)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\binom{n}{k}", settings~)),
    output,
  )
}

///|
test "render delimited block fraction aligned at fraction bar" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // \left( \frac{1}{2} \right): parens sit exactly on the fraction line
  let output =
    #|  1  
    #|(───)
    #|  2  
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left(\\frac{1}{2}\\right)", settings~),
    ),
    output,
  )
  // Other delimiter styles need no special-casing: single chars align the same
  let output =
    #|  a   
    #|[────]
    #|  bc  
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left[\\frac{a}{bc}\\right]", settings~),
    ),
    output,
  )
  // Asymmetric numerator/denominator — still anchored on the bar
  let output =
    #|   x²    
    #|(───────)
    #|  y + z  
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left(\\frac{x^2}{y+z}\\right)", settings~),
    ),
    output,
  )
  // \genfrac with a bar line and delimiters follows the same layout
  let output =
    #|  x  
    #|(───)
    #|  y  
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\genfrac{(}{)}{0.4pt}{1}{x}{y}", settings~),
    ),
    output,
  )
}

///|
test "render delimited block fraction inside expression" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  let output =
    #|      1  
    #|a + (───)
    #|      2  
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("a+\\left(\\frac{1}{2}\\right)", settings~),
    ),
    output,
  )
}

///|
test "render left-right delimiters inline in non-display mode" {
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left(\\frac{1}{2}\\right)")),
    "(1∕2)",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\left( x \\right)")),
    "(x)",
  )
}

///|
test "render fraction alignment extremes" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // Very wide numerator, very narrow denominator
  let output =
    #| aaaaaaa 
    #|─────────
    #|    b    
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{aaaaaaa}{b}", settings~)),
    output,
  )
  // Very narrow numerator, very wide denominator
  let output =
    #|    a    
    #|─────────
    #| bbbbbbb 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{bbbbbbb}", settings~)),
    output,
  )
  // Equal width
  let output =
    #| aaa 
    #|─────
    #| bbb 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{aaa}{bbb}", settings~)),
    output,
  )
}

///|
test "render fractions with configurable slash" {
  let config = @unicode.RenderConfig::make(fraction_slash="/")
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{b}"), config~),
    "a/b",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a+b}{c+d}"), config~),
    "(a+b)/(c+d)",
  )
}

///|
test "block fraction keeps its baseline through groups and scripts" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // An explicit group around the fraction keeps the delimiters on the bar
  let output =
    #|  a  
    #|(───)
    #|  b  
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left({\\frac{a}{b}}\\right)", settings~),
    ),
    output,
  )
  // \left\{ ... \right. aligns the brace on the bar too
  let output =
    #|  a 
    #|{───
    #|  b 
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\left\\{\\frac{a}{b}\\right.", settings~),
    ),
    output,
  )
  // A grouped fraction between atoms aligns them on the bar
  let output =
    #|  b  
    #|a───d
    #|  c  
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("a{\\frac{b}{c}}d", settings~)),
    output,
  )
  // A subscript after a block fraction sits on the bar line
  let output =
    #|  a   
    #|(───)₁
    #|  b   
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\frac{a}{b}_1", settings~)),
    output,
  )
}

///|
test "render \\atop as a stacked fraction without a bar" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // \atop stacks numerator over denominator with no fraction bar
  let output =
    #| a 
    #| b 
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("a \\atop b", settings~)),
    output,
  )
  // \genfrac with a zero/blank bar follows the same layout
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\genfrac{}{}{0pt}{}{a}{b}", settings~),
    ),
    output,
  )
  // A non-zero bar still draws the line
  let output =
    #| a 
    #|───
    #| b 
  @test.assert_eq(
    @unicode.render(
      @katex_parser.parse("\\genfrac{}{}{0.4pt}{}{a}{b}", settings~),
    ),
    output,
  )
  // A bar-less stack under a radical keeps its baseline
  let output =
    #|   a  
    #|√( b )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\sqrt{a \\atop b}", settings~)),
    output,
  )
  // Inline \atop keeps the comma-separated fallback
  @test.assert_eq(@unicode.render(@katex_parser.parse("a \\atop b")), "a,b")
}
