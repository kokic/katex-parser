///|
test "MacroExpander expands simple text macro" {
  let settings = Settings::default()
  settings.macros["\\foo"] = MacroDefinition::Text("xy")
  let expander = MacroExpander::make("\\foo", settings, Math)
  let t0 = expander.expand_next_token().unwrap()
  let t1 = expander.expand_next_token().unwrap()
  let t2 = expander.expand_next_token().unwrap()
  debug_inspect([t0.text, t1.text, t2.text], content="[\"x\", \"y\", \"EOF\"]")
}

///|
test "Namespace restores scoped macro values" {
  let ns : Namespace[MacroDefinition] = Namespace::make({}, {
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
