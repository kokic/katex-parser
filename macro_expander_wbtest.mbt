///|
test "MacroExpander expands simple text macro" {
  let settings = Settings::default()
  settings.macros["\\foo"] = MacroDefinition::Text("xy")
  let expander = MacroExpander::make("\\foo", settings)
  let t0 = expander.expand_next_token().unwrap()
  let t1 = expander.expand_next_token().unwrap()
  let t2 = expander.expand_next_token().unwrap()
  debug_inspect([t0.text, t1.text, t2.text], content="[\"x\", \"y\", \"EOF\"]")
}

///|
test "Namespace restores scoped macro values" {
  let ns : Namespace[MacroDefinition] = Namespace::make(Map([]), {
    "a": MacroDefinition::Text("x"),
  })
  ns.begin_group()
  ns.set("a", Some(MacroDefinition::Text("y")))
  ns.set("b", Some(MacroDefinition::Text("z")))
  debug_inspect(
    (ns.get("a"), ns.get("b")),
    content="(Some(Text(\"y\")), Some(Text(\"z\")))",
  )
  ns.end_group()
  debug_inspect((ns.get("a"), ns.get("b")), content="(Some(Text(\"x\")), None)")
}

///|
test "Namespace local deletion shadows builtins until group ends" {
  let ns : Namespace[MacroDefinition] = Namespace::make(
    { "a": MacroDefinition::Text("builtin") },
    Map([]),
  )
  ns.begin_group()
  ns.set("a", None)
  debug_inspect(ns.get("a"), content="None")
  ns.end_group()
  debug_inspect(ns.get("a"), content="Some(Text(\"builtin\"))")
}

///|
test "MacroExpander treats relax as defined but unexpanded" {
  let expander = MacroExpander::make("\\relax", Settings::default())
  let token = expander.expand_next_token().unwrap()
  inspect(token.text, content="\\relax")
}

///|
test "MacroExpander propagates invalid macro body lexing" {
  let settings = Settings::default()
  settings.macros["\\bad"] = MacroDefinition::Text("\\")
  let expander = MacroExpander::make("\\bad", settings)
  match expander.expand_next_token() {
    Err(UnexpectedCharacter(message~, loc~)) =>
      debug_inspect(
        (message, loc),
        content="(\"Unexpected bare backslash\", Some({ input: \"\\\\\", start: 0, end: 1 }))",
      )
    _ => fail("expected UnexpectedCharacter")
  }
}

///|
test "MacroExpander::scan_argument pushes required argument job" {
  let expander = MacroExpander::make("{xy}z", Settings::default())
  let arg = expander.scan_argument(false).unwrap().unwrap()
  let t0 = expander.expand_next_token().unwrap()
  let t1 = expander.expand_next_token().unwrap()
  let t2 = expander.expand_next_token().unwrap()
  debug_inspect(
    (arg.loc, [t0.text, t1.text, t2.text]),
    content="(Some({ input: \"{xy}z\", start: 0, end: 4 }), [\"x\", \"y\", \"EOF\"])",
  )
}

///|
test "MacroExpander::scan_argument keeps nested braced argument order" {
  let expander = MacroExpander::make("{x{y}z}", Settings::default())
  let arg = expander.scan_argument(false).unwrap().unwrap()
  let t0 = expander.expand_next_token().unwrap()
  let t1 = expander.expand_next_token().unwrap()
  let t2 = expander.expand_next_token().unwrap()
  let t3 = expander.expand_next_token().unwrap()
  let t4 = expander.expand_next_token().unwrap()
  let t5 = expander.expand_next_token().unwrap()
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
  let arg = expander.scan_argument(false).unwrap().unwrap()
  let t0 = expander.expand_next_token().unwrap()
  let t1 = expander.expand_next_token().unwrap()
  debug_inspect(
    (arg.loc, [t0.text, t1.text]),
    content="(Some({ input: \"xy\", start: 0, end: 1 }), [\"x\", \"EOF\"])",
  )
}

///|
test "MacroExpander::scan_argument leaves absent optional argument untouched" {
  let expander = MacroExpander::make("x", Settings::default())
  let arg = expander.scan_argument(true).unwrap()
  let t0 = expander.expand_next_token().unwrap()
  debug_inspect((arg is None, t0.text), content="(true, \"x\")")
}
