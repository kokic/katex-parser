///|
test "MacroExpander infers and substitutes string macro arguments" {
  let settings = Settings::default()
  settings.macros["\\pair"] = MacroDefinition::text("(#1,#2)")
  let expander = MacroExpander::make("\\pair{a}{bc}", settings)
  assert_eq(expanded_text(expander), "(a,bc)")
}

///|
test "MacroExpander substitutes nested braced arguments without outer braces" {
  let settings = Settings::default()
  settings.macros["\\id"] = MacroDefinition::text("#1")
  let expander = MacroExpander::make("\\id{{x}}", settings)
  assert_eq(expanded_text(expander), "{x}")
}

///|
test "MacroExpander ignores spaces before undelimited arguments" {
  let settings = Settings::default()
  settings.macros["\\pair"] = MacroDefinition::text("#1#2")
  let expander = MacroExpander::make("\\pair   x \t y", settings)
  assert_eq(expanded_text(expander), "xy")
}

///|
test "MacroExpander handles escaped placeholder in parameterized body" {
  let settings = Settings::default()
  settings.macros["\\hash"] = MacroDefinition::text("##:#1")
  let expander = MacroExpander::make("\\hash{x}", settings)
  assert_eq(expanded_text(expander), "#:x")
}

///|
test "MacroExpander consumes delimited arguments at group depth zero" {
  let settings = Settings::default()
  let expansion = make_macro_expansion(
    "(#1/#2)",
    num_args=2,
    delimiters=([["["], [","], ["]"]] : Array[Array[String]]),
  )
  settings.macros["\\F"] = MacroDefinition::expansion(expansion)
  let expander = MacroExpander::make("\\F[{x,y},z]", settings)
  assert_eq(expanded_text(expander), "(x,y/z)")
}

///|
test "MacroExpander permits empty delimited argument" {
  let expander = MacroExpander::make(",x", Settings::default())
  let arg = expander.consume_arg(Some([","]))
  assert_true(arg.tokens.is_empty())
  assert_eq(expander.pop_token().text, "x")
}

///|
test "MacroExpander matches multi-token delimiter after partial mismatch" {
  let expander = MacroExpander::make("xacaby", Settings::default())
  let arg = expander.consume_arg(Some(["a", "b"]))
  assert_eq([arg.tokens[0].text, arg.tokens[1].text, arg.tokens[2].text], [
    "c", "a", "x",
  ])
  assert_eq(expander.pop_token().text, "y")
}

///|
test "MacroExpander permits opening brace as a definition delimiter" {
  let expander = MacroExpander::make("{x", Settings::default())
  let arg = expander.consume_arg(Some(["{"]))
  assert_true(arg.tokens.is_empty())
  assert_eq(expander.pop_token().text, "x")
}

///|
test "MacroExpander checks macro invocation prefix delimiters" {
  let expander = MacroExpander::make("[x", Settings::default())
  let args = expander.consume_args(1, Some([["["], []]))
  assert_eq(args.length(), 1)
  assert_eq(args[0][0].text, "x")

  let mismatch = MacroExpander::make("(x", Settings::default())
  match
    capture_parse_result(() => mismatch.consume_args(1, Some([["["], []]))) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "Use of the macro doesn't match its definition")
    _ => fail("expected delimiter mismatch")
  }
}

///|
test "MacroExpander validates delimiter table arity" {
  let expander = MacroExpander::make("", Settings::default())
  match capture_parse_result(() => expander.consume_args(2, Some([[]]))) {
    Err(InvalidArgument(message~, loc~)) => {
      assert_eq(
        message, "The length of delimiters doesn't match the number of args!",
      )
      assert_eq(loc, None)
    }
    _ => fail("expected delimiter arity error")
  }
}

///|
test "MacroExpander reports incomplete and invalid placeholders" {
  let incomplete_settings = Settings::default()
  incomplete_settings.macros["\\bad"] = MacroDefinition::expansion(
    make_macro_expansion("#", num_args=1),
  )
  let incomplete = MacroExpander::make("\\bad{x}", incomplete_settings)
  match capture_parse_result(() => incomplete.expand_next_token()) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "Incomplete placeholder at end of macro body")
    _ => fail("expected incomplete placeholder error")
  }

  let invalid_settings = Settings::default()
  invalid_settings.macros["\\bad"] = MacroDefinition::expansion(
    make_macro_expansion("#x", num_args=1),
  )
  let invalid = MacroExpander::make("\\bad{y}", invalid_settings)
  match capture_parse_result(() => invalid.expand_next_token()) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "Not a valid argument number")
    _ => fail("expected invalid placeholder error")
  }
}

///|
test "MacroExpander reports EOF and extra brace in arguments" {
  let eof = MacroExpander::make("{x", Settings::default())
  match capture_parse_result(() => eof.consume_arg(None)) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(
        message, "Unexpected end of input in a macro argument, expected '}'",
      )
    _ => fail("expected argument EOF error")
  }

  let extra = MacroExpander::make("}", Settings::default())
  match capture_parse_result(() => extra.consume_arg(None)) {
    Err(InvalidArgument(message~, ..)) => assert_eq(message, "Extra }")
    _ => fail("expected extra brace error")
  }
}

///|
test "MacroExpander reports the unmatched part of delimiter sequence" {
  let expander = MacroExpander::make("xa", Settings::default())
  match capture_parse_result(() => expander.consume_arg(Some(["a", "b"]))) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(
        message, "Unexpected end of input in a macro argument, expected 'b'",
      )
    _ => fail("expected partial delimiter EOF error")
  }
}
