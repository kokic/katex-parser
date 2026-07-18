///|
test "render superscript and subscript variants" {
  @test.assert_eq(render(@katex_parser.parse("x^{12}")), "x¹²")
  @test.assert_eq(render(@katex_parser.parse("x_{ij}")), "xᵢⱼ")
}

///|
test "render superscript and subscript with compound expressions" {
  @test.assert_eq(render(@katex_parser.parse("x^{a+b}")), "xᵃ⁺ᵇ")
  @test.assert_eq(render(@katex_parser.parse("x_{i+j}")), "xᵢ₊ⱼ")
  @test.assert_eq(render(@katex_parser.parse("x^2_n")), "xₙ²")
  @test.assert_eq(render(@katex_parser.parse("x_i^j")), "xᵢʲ")
}
