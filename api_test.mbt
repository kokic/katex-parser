///|
test "parse a basic expression" {
  let nodes = @katex_parser.parse("x")
  match nodes {
    [MathOrd(text="x", ..)] => ()
    _ => @test.fail("expected one math ordinal")
  }
}

///|
test "parse uses text macro settings" {
  let macros = Map([("\\foo", "x")])
  let settings = @katex_parser.Settings::make(macros~)
  let nodes = @katex_parser.parse("\\foo", settings~)
  match nodes {
    [MathOrd(text="x", ..)] => ()
    _ => @test.fail("expected macro expansion")
  }
}

///|
test "parse supports parameterized text macros" {
  let macros = Map([("\\vect", "\\mathbf{#1}")])
  let settings = @katex_parser.Settings::make(macros~)
  let nodes = @katex_parser.parse("\\vect{x}", settings~)
  match nodes {
    [Font(font="mathbf", ..)] => ()
    _ => @test.fail("expected parameterized macro expansion")
  }
}

///|
test "settings accepts strict callbacks with locations" {
  let handler : @katex_parser.StrictHandler = (_code, _message, _loc) => Ignore
  let settings = @katex_parser.Settings::make(strict=Callback(handler))
  let nodes = @katex_parser.parse("x", settings~)
  @test.assert_eq(nodes.length(), 1)
}

///|
test "parse failures expose source locations" {
  try @katex_parser.parse("\\unknown") catch {
    UndefinedControlSequence(loc=Some(loc), ..) => {
      @test.assert_eq(loc.start, 0)
      @test.assert_eq(loc.end, 8)
    }
    _ => @test.fail("expected an undefined control sequence")
  } noraise {
    _ => @test.fail("expected parsing to fail")
  }
}
