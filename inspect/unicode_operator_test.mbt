///|
test "named operators keep a space before their operand" {
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det A")), "det A")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\sin x")), "sin x")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\lim f")), "lim f")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det A_1")), "det A₁")
  // Opening delimiters already provide visual separation
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det(x)")), "det(x)")
  // \left(...\right) is \mathinner: thin space before it (mop → minner)
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det\\left(x\\right)")), "det (x)")
}

///|
test "display mode stacks operator limits above and below" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  // \sum: upper limit above, lower below, baseline on the operator line
  let output =
    #| n   
    #| ∑  x
    #|i=0  
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\sum_{i=0}^n x", settings~)),
    output,
  )
  // \lim: named operator with limits
  let output =
    #|lim f
    #|x→0  
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\lim_{x\\to 0} f", settings~)),
    output,
  )
  // Integrals keep side limits even in display mode (limits=false)
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\int_0^1 x", settings~)),
    "∫₀¹ x",
  )
  // Inline mode keeps side limits
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\sum_{i=0}^n x")),
    "∑ᵢ₌₀ⁿ x",
  )
}

///|
test "operatorname star draws limits in every style" {
  // Inline \operatorname* still stacks the sublimit
  let output =
    #|argmin f
    #|  x     
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\operatorname*{argmin}_{x} f")),
    output,
  )
  // Plain \operatorname keeps side limits
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\operatorname{argmin}_{x} f")),
    "argminₓ f",
  )
}

///|
test "strip backslash prefix in fallback notation" {
  // Named operators render without the backslash
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\sin")), "sin")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\lim_{x}")), "limₓ")
  @test.assert_eq(@unicode.render(@katex_parser.parse("\\det A")), "det A")
  // Nested fallbacks strip each level's backslash
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\widehat{\\overrightarrow{x}}")),
    "widehat(overrightarrow(x))",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\hat{\\cancel{x}}")),
    "hat(cancel(x))",
  )
  @test.assert_eq(
    @unicode.render(@katex_parser.parse("\\underleftrightarrow{x}")),
    "underaccent(underleftrightarrow,x)",
  )
}
