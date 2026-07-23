///|
test "render \\def inline definition and usage" {
  @test.assert_eq(
    render(@katex_parser.parse("\\def\\foo{x} \\foo")),
    "x",
  )
}

///|
test "render \\gdef inline definition and usage" {
  @test.assert_eq(
    render(@katex_parser.parse("\\gdef\\foo{x} \\foo")),
    "x",
  )
}

///|
test "render \\newcommand inline definition and usage" {
  @test.assert_eq(
    render(@katex_parser.parse("\\newcommand{\\foo}{x} \\foo")),
    "x",
  )
}

///|
test "render macro with parameters" {
  @test.assert_eq(
    render(@katex_parser.parse("\\def\\vect#1{\\mathbf{#1}} \\vect{x}")),
    "𝐱",
  )
}

///|
test "render macro with multiple parameters" {
  @test.assert_eq(
    render(@katex_parser.parse("\\def\\div#1#2{\\frac{#1}{#2}} \\div{a}{b}")),
    "a∕b",
  )
}

///|
test "render macro expanding to fraction" {
  @test.assert_eq(
    render(@katex_parser.parse("\\def\\half{\\frac{1}{2}} \\half")),
    "1∕2",
  )
}

///|
test "render macro expanding to operator with scripts" {
  @test.assert_eq(
    render(@katex_parser.parse("\\def\\R{\\mathbb{R}} \\R_1^2")),
    "ℝ₁²",
  )
}

///|
test "render macro redefinition" {
  @test.assert_eq(
    render(@katex_parser.parse("\\def\\foo{a} \\foo \\def\\foo{b} \\foo")),
    "ab",
  )
}

///|
test "render macro expanding to compound expression" {
  @test.assert_eq(
    render(@katex_parser.parse("\\def\\expr{a+b} \\expr")),
    "a + b",
  )
}

///|
test "render pre-defined text macro via settings" {
  let macros = Map([("\\foo", "x")])
  let settings = @katex_parser.Settings::make(macros~)
  @test.assert_eq(
    render(@katex_parser.parse("\\foo", settings=settings)),
    "x",
  )
}

///|
test "render pre-defined parameterized macro via settings" {
  let macros = Map([("\\vect", "\\mathbf{#1}")])
  let settings = @katex_parser.Settings::make(macros~)
  @test.assert_eq(
    render(@katex_parser.parse("\\vect{x}", settings=settings)),
    "𝐱",
  )
}

///|
test "render pre-defined macro with scripts" {
  let macros = Map([("\\R", "\\mathbb{R}")])
  let settings = @katex_parser.Settings::make(macros~)
  @test.assert_eq(
    render(@katex_parser.parse("\\R_1^2", settings=settings)),
    "ℝ₁²",
  )
}
