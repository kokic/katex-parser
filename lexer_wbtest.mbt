///|
fn expect_unexpected_character(input : String) -> Unit raise {
  match Lexer::make(input).lex() {
    Err(UnexpectedCharacter(message~, loc~)) => {
      assert_eq(message, "Unexpected character: '" + input + "'")
      assert_eq(loc, Some(SourceLocation::make(input, start=0, end=1)))
    }
    _ => fail("expected UnexpectedCharacter")
  }
}

///|
test "Lexer::lex collapses regular whitespace with exact location" {
  let lexer = Lexer::make(" \r\n\tx")
  let whitespace = lexer.lex().unwrap()
  let x = lexer.lex().unwrap()
  debug_inspect(
    (whitespace.text, whitespace.loc, x.text, x.loc),
    content=(
      #|(
      #|  " ",
      #|  Some({ input: " \r\n\tx", start: 0, end: 4 }),
      #|  "x",
      #|  Some({ input: " \r\n\tx", start: 4, end: 5 }),
      #|)
    ),
  )
}

///|
test "Lexer::lex matches KaTeX control-space newline rules" {
  let lexer = Lexer::make("\\ \r\t\n \tx\\\n \ty\\\n\nz")
  let tokens : Array[(String, SourceLocation?)] = []
  for _ in 0..<8 {
    let token = lexer.lex().unwrap()
    tokens.push((token.text, token.loc))
  }
  let input = "\\ \r\t\n \tx\\\n \ty\\\n\nz"
  assert_eq(tokens, [
    ("\\ ", Some(SourceLocation::make(input, start=0, end=7))),
    ("x", Some(SourceLocation::make(input, start=7, end=8))),
    ("\\ ", Some(SourceLocation::make(input, start=8, end=12))),
    ("y", Some(SourceLocation::make(input, start=12, end=13))),
    ("\\ ", Some(SourceLocation::make(input, start=13, end=15))),
    (" ", Some(SourceLocation::make(input, start=15, end=16))),
    ("z", Some(SourceLocation::make(input, start=16, end=17))),
    ("EOF", Some(SourceLocation::make(input, start=17, end=17))),
  ])
}

///|
test "Lexer::lex strips trailing whitespace from control-word text" {
  let lexer = Lexer::make("\\frac \r\n\tx")
  let control_word = lexer.lex().unwrap()
  let x = lexer.lex().unwrap()
  debug_inspect(
    (control_word.text, control_word.loc, x.text, x.loc),
    content=(
      #|(
      #|  "\\frac",
      #|  Some({ input: "\\frac \r\n\tx", start: 0, end: 9 }),
      #|  "x",
      #|  Some({ input: "\\frac \r\n\tx", start: 9, end: 10 }),
      #|)
    ),
  )
}

///|
test "Lexer::lex treats at-sign as a control-word letter" {
  let lexer = Lexer::make("\\foo@bar x")
  let control_word = lexer.lex().unwrap()
  let x = lexer.lex().unwrap()
  assert_eq(control_word.text, "\\foo@bar")
  assert_eq(
    control_word.loc,
    Some(SourceLocation::make("\\foo@bar x", start=0, end=9)),
  )
  assert_eq(x.text, "x")
}

///|
test "Lexer::lex returns a control symbol as one token" {
  let lexer = Lexer::make("\\%x")
  let control_symbol = lexer.lex().unwrap()
  let x = lexer.lex().unwrap()
  debug_inspect(
    (control_symbol.text, control_symbol.loc, x.text),
    content=(
      #|("\\%", Some({ input: "\\%x", start: 0, end: 2 }), "x")
    ),
  )
}

///|
test "Lexer::lex attaches combining marks to BMP and astral bases" {
  let lexer = Lexer::make("a\u{0301}\u{036f}𝛼\u{0302}")
  let bmp = lexer.lex().unwrap()
  let astral = lexer.lex().unwrap()
  debug_inspect(
    (bmp.text, bmp.loc, astral.text, astral.loc),
    content=(
      #|(
      #|  "áͯ",
      #|  Some({ input: "áͯ𝛼̂", start: 0, end: 3 }),
      #|  "𝛼̂",
      #|  Some({ input: "áͯ𝛼̂", start: 3, end: 6 }),
      #|)
    ),
  )
}

///|
test "Lexer::lex captures complete starred and unstarred verb tokens" {
  let lexer = Lexer::make("\\verb|a b|x\\verb*+c d+y\\verb@e f@z")
  let verb = lexer.lex().unwrap()
  let x = lexer.lex().unwrap()
  let starred = lexer.lex().unwrap()
  let y = lexer.lex().unwrap()
  let at_delimiter = lexer.lex().unwrap()
  let z = lexer.lex().unwrap()
  debug_inspect(
    [verb.text, x.text, starred.text, y.text, at_delimiter.text, z.text],
    content="[\"\\\\verb|a b|\", \"x\", \"\\\\verb*+c d+\", \"y\", \"\\\\verb@e f@\", \"z\"]",
  )
  debug_inspect(
    (verb.loc, starred.loc, at_delimiter.loc),
    content=(
      #|(
      #|  Some({ input: "\\verb|a b|x\\verb*+c d+y\\verb@e f@z", start: 0, end: 10 }),
      #|  Some({ input: "\\verb|a b|x\\verb*+c d+y\\verb@e f@z", start: 11, end: 22 }),
      #|  Some({ input: "\\verb|a b|x\\verb*+c d+y\\verb@e f@z", start: 23, end: 33 }),
      #|)
    ),
  )
}

///|
test "Lexer::lex allows alphabetic delimiter for starred verb" {
  let lexer = Lexer::make("\\verb*a bodya")
  let token = lexer.lex().unwrap()
  assert_eq(token.text, "\\verb*a bodya")
}

///|
test "Lexer::lex falls back to control word for unterminated verb" {
  let newline = Lexer::make("\\verb|hello\nworld|")
  let at_eof = Lexer::make("\\verb*|hello")
  let n0 = newline.lex().unwrap()
  let n1 = newline.lex().unwrap()
  let e0 = at_eof.lex().unwrap()
  let e1 = at_eof.lex().unwrap()
  debug_inspect(
    [n0.text, n1.text, e0.text, e1.text],
    content="[\"\\\\verb\", \"|\", \"\\\\verb\", \"*\"]",
  )
}

///|
test "Lexer::lex skips comments through terminating newline" {
  let lexer = Lexer::make("x% comment\ny")
  let x = lexer.lex().unwrap()
  let y = lexer.lex().unwrap()
  let eof = lexer.lex().unwrap()
  debug_inspect([x.text, y.text, eof.text], content="[\"x\", \"y\", \"EOF\"]")
}

///|
test "Lexer::lex reports comment at end before EOF" {
  let diagnostics : Array[(String, String)] = []
  let lexer = Lexer::make("% comment", report_nonstrict=(code, message) => {
    diagnostics.push((code, message))
    Ok(())
  })
  let eof = lexer.lex().unwrap()
  assert_eq(eof.text, "EOF")
  assert_eq(diagnostics, [
    (
      "commentAtEnd", "% comment has no terminating newline; LaTeX would fail because of commenting the end of math mode (e.g. $)",
    ),
  ])
}

///|
test "Lexer::lex propagates a nonstrict reporter error" {
  let lexer = Lexer::make("% comment", report_nonstrict=(_code, _message) => {
    Err(InvalidArgument(message="strict commentAtEnd", loc=None))
  })
  match lexer.lex() {
    Err(InvalidArgument(message~, loc~)) => {
      assert_eq(message, "strict commentAtEnd")
      assert_eq(loc, None)
    }
    _ => fail("expected reporter error")
  }
}

///|
test "Lexer::set_catcode changes comment characters" {
  let percent = Lexer::make("%x")
  percent.set_catcode("%", 13)
  let p0 = percent.lex().unwrap()
  let p1 = percent.lex().unwrap()
  let custom = Lexer::make("! ignored\nx")
  custom.set_catcode("!", 14)
  let c0 = custom.lex().unwrap()
  debug_inspect([p0.text, p1.text, c0.text], content="[\"%\", \"x\", \"x\"]")
}

///|
test "Lexer::lex rejects KaTeX-excluded BMP ranges" {
  expect_unexpected_character("\u{0000}")
  expect_unexpected_character("\u{001f}")
  expect_unexpected_character("\u{2028}")
  expect_unexpected_character("\u{2029}")
  expect_unexpected_character("\u{e000}")
  expect_unexpected_character("\u{f8ff}")
}

///|
test "Lexer::lex permits excluded bare characters as control symbols" {
  let lexer = Lexer::make("\\\u{0000}\\\u{2028}\\\u{e000}")
  let control = lexer.lex().unwrap()
  let line_separator = lexer.lex().unwrap()
  let private_use = lexer.lex().unwrap()
  assert_eq(control.text, "\\\u{0000}")
  assert_eq(line_separator.text, "\\\u{2028}")
  assert_eq(private_use.text, "\\\u{e000}")
}

///|
test "Lexer::lex reports unexpected character at current UTF-16 offset" {
  let input = "x\u{e000}"
  let lexer = Lexer::make(input)
  assert_eq(lexer.lex().unwrap().text, "x")
  match lexer.lex() {
    Err(UnexpectedCharacter(message~, loc~)) => {
      assert_eq(message, "Unexpected character: '\u{e000}'")
      assert_eq(loc, Some(SourceLocation::make(input, start=1, end=2)))
    }
    _ => fail("expected UnexpectedCharacter")
  }
}

///|
test "Lexer code-unit predicates reject bare surrogates" {
  assert_true(is_high_surrogate(0xd800))
  assert_true(is_high_surrogate(0xdbff))
  assert_true(is_low_surrogate(0xdc00))
  assert_true(is_low_surrogate(0xdfff))
  assert_false(is_regular_code_unit(0xd800))
  assert_false(is_regular_code_unit(0xdc00))
}

///|
test "Lexer::lex rejects a bare backslash with KaTeX error shape" {
  expect_unexpected_character("\\")
}

///|
test "Lexer regular-code-unit boundaries match KaTeX" {
  assert_true(is_regular_code_unit(0x0021))
  assert_true(is_regular_code_unit(0x005b))
  assert_false(is_regular_code_unit(0x005c))
  assert_true(is_regular_code_unit(0x005d))
  assert_true(is_regular_code_unit(0x2027))
  assert_false(is_regular_code_unit(0x2028))
  assert_false(is_regular_code_unit(0x2029))
  assert_true(is_regular_code_unit(0x202a))
  assert_true(is_regular_code_unit(0xd7ff))
  assert_false(is_regular_code_unit(0xe000))
  assert_false(is_regular_code_unit(0xf8ff))
  assert_true(is_regular_code_unit(0xf900))
  assert_true(is_regular_code_unit(0xffff))
}
