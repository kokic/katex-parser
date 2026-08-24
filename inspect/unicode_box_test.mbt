///|
test "render \\boxed as a unicode box" {
  let output =
    #|┌─┐
    #|│x│
    #|└─┘
  @test.assert_eq(@unicode.render(@katex.parse("\\boxed{x}")), output)

  let output =
    #|┌───────┐
    #|│     c │
    #|│π = ───│
    #|│     d │
    #|└───────┘
  @test.assert_eq(
    @unicode.render(@katex.parse("\\boxed{\\pi=\\frac c d}")),
    output,
  )
}

///|
test "boxed content centers in display mode" {
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #|    ┌───────┐
    #|    │     c │
    #|x = │π = ───│
    #|    │     d │
    #|    └───────┘
  @test.assert_eq(
    @unicode.render(@katex.parse("x = \\boxed{\\pi=\\frac c d}", settings~)),
    output,
  )
}

///|
test "render boxes and fraction bars in ascii style" {
  let config = @unicode.RenderConfig::make(line_style=@unicode.LineStyle::Ascii)
  let output =
    #|---
    #||x|
    #|---
  @test.assert_eq(@unicode.render(@katex.parse("\\boxed{x}"), config~), output)

  let output =
    #|---------
    #||     c |
    #||π = ---|
    #||     d |
    #|---------
  @test.assert_eq(
    @unicode.render(@katex.parse("\\boxed{\\pi=\\frac c d}"), config~),
    output,
  )
  let settings = @katex.Settings::make(display_mode=true)
  let output =
    #| a 
    #|---
    #| b 
  @test.assert_eq(
    @unicode.render(@katex.parse("\\frac{a}{b}", settings~), config~),
    output,
  )
}
