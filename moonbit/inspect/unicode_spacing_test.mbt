///|
test "render block math with horizontal alignment" {
  let source =
    #|\sum_{n\ge1}\frac{1}{n^2}=\frac{\pi^2}{6}

  let output =
    #|     1      π² 
    #| ∑  ──── = ────
    #|n≥1  n²     6  

  let settings = @katex.Settings::make(display_mode=true)
  @test.assert_eq(@unicode.render(@katex.parse(source, settings~)), output)
}

///|
test "spacing macros render as plain spaces" {
  @test.assert_eq(@unicode.render(@katex.parse("a\\,b")), "a b")
  @test.assert_eq(@unicode.render(@katex.parse("a\\:b")), "a b")
  @test.assert_eq(@unicode.render(@katex.parse("a\\;b")), "a b")
  @test.assert_eq(@unicode.render(@katex.parse("a\\enspace b")), "a b")
  @test.assert_eq(@unicode.render(@katex.parse("a\\quad b")), "a  b")
  @test.assert_eq(@unicode.render(@katex.parse("a\\qquad b")), "a    b")
  // Negative spaces have no plain-text representation
  @test.assert_eq(@unicode.render(@katex.parse("a\\!b")), "ab")
  @test.assert_eq(@unicode.render(@katex.parse("\\int\\!dx")), "∫ dx")
  // Other units keep the kern() fallback
  @test.assert_eq(@unicode.render(@katex.parse("x\\kern{1pt}y")), "xkern(1pt)y")
}

///|
test "toplevel infix operator spacing" {
  @test.assert_eq(
    @unicode.render(
      @katex.parse("\\R_{\\ge 0}^* = \\R_{\\ge 0} \\cup \\{\\infty\\}"),
    ),
    "ℝ_(≥0)^∗ = ℝ_(≥0) ∪ {∞}",
  )
}

///|

///|
test "prime superscripts render as apostrophes" {
  // ' is a superscript prime, equivalent to ^\prime (KaTeX Parser.ts)
  @test.assert_eq(@unicode.render(@katex.parse("A'")), "A'")
  @test.assert_eq(@unicode.render(@katex.parse("A^\\prime")), "A'")
  @test.assert_eq(@unicode.render(@katex.parse("A''")), "A''")
  @test.assert_eq(@unicode.render(@katex.parse("A^{\\prime\\prime}")), "A''")
  @test.assert_eq(@unicode.render(@katex.parse("f'(x)")), "f'(x)")
  // A superscript with primes and scriptable content keeps the scripts
  @test.assert_eq(@unicode.render(@katex.parse("A'^2")), "A'²")
  // Bare \prime at the baseline keeps the prime character
  @test.assert_eq(@unicode.render(@katex.parse("A\\prime")), "A′")
  // Double prime conflicts with an existing superscript
  try {
    let _ = @katex.parse("A^2'")
    ()
  } catch {
    @katex.DoubleSuperscript(..) => ()
    _ => @test.fail("expected a double superscript error")
  } noraise {
    _ => @test.fail("expected A^2' to fail")
  }
}

///|
test "TeX spacing around infix operators" {
  // Binary operators get spacing
  @test.assert_eq(@unicode.render(@katex.parse("a+b")), "a + b")
  // Relation operators get spacing
  @test.assert_eq(@unicode.render(@katex.parse("a=b")), "a = b")
  // No spacing inside subscripts (tight mode)
  @test.assert_eq(@unicode.render(@katex.parse("x_{a+b}")), "x_(a+b)")
  // No spacing inside superscripts (tight mode)
  @test.assert_eq(@unicode.render(@katex.parse("x^{a+b}")), "xᵃ⁺ᵇ")
  // Bin at start of group becomes ord (no left spacing)
  @test.assert_eq(@unicode.render(@katex.parse("{+x}")), "+x")
  // Multiple operators: spacing between each
  @test.assert_eq(
    @unicode.render(@katex.parse("a + b = c \\cup d")),
    "a + b = c ∪ d",
  )
}
