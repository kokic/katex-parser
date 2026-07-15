///|
test "MacroExpander expands simple text macro" {
  let settings = Settings::default()
  settings.macros["\\foo"] = MacroDefinition::text("xy")
  let expander = MacroExpander::make("\\foo", settings)
  let t0 = expander.expand_next_token()
  let t1 = expander.expand_next_token()
  let t2 = expander.expand_next_token()
  debug_inspect([t0.text, t1.text, t2.text], content="[\"x\", \"y\", \"EOF\"]")
}

///|
test "MacroExpander treats relax as defined but unexpanded" {
  let expander = MacroExpander::make("\\relax", Settings::default())
  let token = expander.expand_next_token()
  inspect(token.text, content="\\relax")
}

///|
test "MacroExpander propagates invalid macro body lexing" {
  let settings = Settings::default()
  settings.macros["\\bad"] = MacroDefinition::text("\\")
  let expander = MacroExpander::make("\\bad", settings)
  match capture_parse_result(() => expander.expand_next_token()) {
    Err(UnexpectedCharacter(message~, loc~)) => {
      assert_eq(message, "Unexpected character: '\\'")
      assert_eq(loc, Some(SourceLocation::make("\\", start=0, end=1)))
    }
    _ => fail("expected UnexpectedCharacter")
  }
}

///|
test "MacroExpander::scan_argument pushes required argument job" {
  let expander = MacroExpander::make("{xy}z", Settings::default())
  let arg = expander.scan_argument(false).unwrap()
  let t0 = expander.expand_next_token()
  let t1 = expander.expand_next_token()
  let t2 = expander.expand_next_token()
  debug_inspect(
    (arg.loc, [t0.text, t1.text, t2.text]),
    content="(Some({ input: \"{xy}z\", start: 0, end: 4 }), [\"x\", \"y\", \"EOF\"])",
  )
}

///|
test "MacroExpander::scan_argument keeps nested braced argument order" {
  let expander = MacroExpander::make("{x{y}z}", Settings::default())
  let arg = expander.scan_argument(false).unwrap()
  let t0 = expander.expand_next_token()
  let t1 = expander.expand_next_token()
  let t2 = expander.expand_next_token()
  let t3 = expander.expand_next_token()
  let t4 = expander.expand_next_token()
  let t5 = expander.expand_next_token()
  debug_inspect(
    (arg.loc, [t0.text, t1.text, t2.text, t3.text, t4.text, t5.text]),
    content=(
      #|(
      #|  Some({ input: "{x{y}z}", start: 0, end: 7 }),
      #|  ["x", "{", "y", "}", "z", "EOF"],
      #|)
    ),
  )
}

///|
test "MacroExpander::scan_argument uses one non-braced token as required argument" {
  let expander = MacroExpander::make("xy", Settings::default())
  let arg = expander.scan_argument(false).unwrap()
  let t0 = expander.expand_next_token()
  let t1 = expander.expand_next_token()
  debug_inspect(
    (arg.loc, [t0.text, t1.text]),
    content="(Some({ input: \"xy\", start: 0, end: 1 }), [\"x\", \"EOF\"])",
  )
}

///|
test "MacroExpander::scan_argument leaves absent optional argument untouched" {
  let expander = MacroExpander::make("  x", Settings::default())
  let arg = expander.scan_argument(true)
  let t0 = expander.expand_next_token()
  debug_inspect((arg is None, t0.text), content="(true, \"x\")")
}

///|
test "MacroExpander::scan_argument pushes nested optional argument job" {
  let expander = MacroExpander::make("[x{y}]z", Settings::default())
  let arg = expander.scan_argument(true).unwrap()
  let tokens : Array[String] = []
  for _ in 0..<5 {
    tokens.push(expander.expand_next_token().text)
  }
  assert_eq(tokens, ["x", "{", "y", "}", "EOF"])
  assert_eq(arg.loc, Some(SourceLocation::make("[x{y}]z", start=0, end=6)))
  assert_eq(expander.expand_next_token().text, "z")
}
