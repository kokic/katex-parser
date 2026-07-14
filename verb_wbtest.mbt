///|
test "parser produces Verb AST for starred and unstarred tokens" {
  match parse("\\verb|a b|\\verb*+c  d+\\verb@e f@") {
    Ok(
      [
        Verb(mode=Text, loc=None, body="a b", star=false),
        Verb(mode=Text, loc=None, body="c  d", star=true),
        Verb(mode=Text, loc=None, body="e f", star=false),
      ]
    ) => ()
    _ => fail("unexpected verb AST")
  }
}

///|
test "starred verb accepts alphabetic delimiter" {
  match parse("\\verb*a bodya") {
    Ok([Verb(mode=Text, loc=None, body=" body", star=true)]) => ()
    _ => fail("expected starred alphabetic verb delimiter")
  }
}

///|
test "verb preserves TeX-special characters without parsing" {
  match parse("\\verb|\\alpha^_{}~%#&|\\verb!!") {
    Ok(
      [
        Verb(mode=Text, body="\\alpha^_{}~%#&", star=false, ..),
        Verb(mode=Text, body="", star=false, ..),
      ]
    ) => ()
    _ => fail("verb body was parsed or altered")
  }
}

///|
test "unterminated verb uses the registered fallback error" {
  for input in ["\\verb|hello", "\\verb*|hello", "\\verb|hello\nworld|"] {
    match parse(input) {
      Err(InvalidArgument(message~, loc=None)) =>
        assert_eq(
          message, "\\verb ended by end of line instead of matching delimiter",
        )
      _ => fail("expected unterminated verb error")
    }
  }
}

///|
test "verb token recognition does not capture longer control words" {
  assert_true(is_verb_token("\\verb|x|"))
  assert_true(is_verb_token("\\verb*a xa"))
  assert_false(is_verb_token("\\verbatim"))
  match parse("\\verbatim") {
    Err(UndefinedControlSequence(name="\\verbatim", ..)) => ()
    _ => fail("longer control word was treated as verb")
  }
}

///|
test "verb parser defends its lexer invariant" {
  match parse_verb_token("\\verb|x!") {
    Err(InternalInvariant(message~)) =>
      assert_eq(
        message, "\\verb assertion failed -- please report what input caused this bug",
      )
    _ => fail("expected mismatched verb delimiter invariant")
  }
}
