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

///|
test "color model syntax is rejected like KaTeX" {
  let rejected = try {
    let _ = @katex_parser.parse("\\color[HTML]{FF0000} x")
    false
  } catch {
    InvalidArgument(message=_, loc=_) => true
    _ => false
  }
  @test.assert_eq(rejected, true)
}

///|
test "trailing comment reports in strict error mode" {
  let settings = @katex_parser.Settings::make(strict=Error)
  let raised = try {
    let _ = @katex_parser.parse("a % comment without newline", settings~)
    false
  } catch {
    InvalidArgument(message=_, loc=_) => true
    _ => false
  }
  @test.assert_eq(raised, true)
}

///|
test "trailing comment warns in strict warn mode" {
  let warnings : Array[String] = []
  let handler : @katex_parser.StrictWarningHandler = message => {
    warnings.push(message)
  }
  let settings = @katex_parser.Settings::make(
    strict=Warn,
    strict_warning_handler=handler,
  )
  let _ = @katex_parser.parse("a % comment without newline", settings~)
  @test.assert_eq(warnings.length(), 1)
  @test.assert_eq(warnings[0].contains("commentAtEnd"), true)
}

///|
test "unicode text in math mode reports in strict mode" {
  let strict = @katex_parser.Settings::make(strict=Error)
  let raised = try {
    let _ = @katex_parser.parse("é + 1", settings=strict)
    false
  } catch {
    InvalidArgument(message=_, loc=_) => true
    _ => false
  }
  // Decomposed accented Latin letter in math mode
  @test.assert_eq(raised, true)
  // Latin-1 fallback letter (Ð Þ þ, extraLatin)
  let raised = try {
    let _ = @katex_parser.parse("Ð", settings=strict)
    false
  } catch {
    InvalidArgument(message=_, loc=_) => true
    _ => false
  }
  @test.assert_eq(raised, true)
  // Supported script character (Cyrillic) in math mode
  let raised = try {
    let _ = @katex_parser.parse("ж", settings=strict)
    false
  } catch {
    InvalidArgument(message=_, loc=_) => true
    _ => false
  }
  @test.assert_eq(raised, true)
  // Unsupported codepoint (en dash) reports unknownSymbol
  let raised = try {
    let _ = @katex_parser.parse("–", settings=strict)
    false
  } catch {
    InvalidArgument(message=_, loc=_) => true
    _ => false
  }
  @test.assert_eq(raised, true)
}

///|
test "unicode text stays permissive without strict mode" {
  @test.assert_eq(@katex_parser.parse("é + ж").length(), 3)
  @test.assert_eq(@katex_parser.parse("–").length(), 1)
}

///|
test "implicit commands do not raise undefined control sequence" {
  // \limits reaching the parser breaks the group instead of being reported
  // as an undefined control sequence (KaTeX implicitCommands)
  let raised = try {
    let _ = @katex_parser.parse("{\\limits}")
    "no error"
  } catch {
    UndefinedControlSequence(..) => "undefined"
    ExpectedToken(..) => "expected token"
    _ => "other"
  }
  @test.assert_eq(raised, "expected token")
}
