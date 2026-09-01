///|
test "render superscript and subscript variants" {
  @test.assert_eq(@unicode.render(@katex.parse("x^{12}")), "x¹²")
  @test.assert_eq(@unicode.render(@katex.parse("x_{ij}")), "xᵢⱼ")
}

///|
test "render superscript and subscript with compound expressions" {
  @test.assert_eq(@unicode.render(@katex.parse("x^{a+b}")), "xᵃ⁺ᵇ")
  @test.assert_eq(@unicode.render(@katex.parse("x_{i+j}")), "xᵢ₊ⱼ")
  @test.assert_eq(@unicode.render(@katex.parse("x^2_n")), "xₙ²")
  @test.assert_eq(@unicode.render(@katex.parse("x_i^j")), "xᵢʲ")
}
