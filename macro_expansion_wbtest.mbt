///|
test "MacroExpander future and pop_token preserve unexpanded lookahead" {
  let expander = MacroExpander::make("xy", Settings::default())
  let first = expander.future()
  assert_eq(first.text, "x")
  assert_eq(expander.future().text, "x")
  assert_eq(expander.pop_token().text, "x")
  assert_eq(expander.pop_token().text, "y")
}

///|
test "MacroExpander expands dynamic text and structured replacements" {
  let dynamic : Map[String, MacroHandler] = {
    "\\mode": context => mode_handler(context),
    "\\structured": structured_dynamic_handler,
  }
  let expander = MacroExpander::make(
    "\\mode\\structured",
    Settings::default(),
    dynamic_macros=dynamic,
  )
  assert_eq(expanded_text(expander), "Mxy")
}

///|
test "MacroExpander infers arguments returned by dynamic text macro" {
  let dynamic : Map[String, MacroHandler] = {
    "\\dynamic": context => parameter_dynamic_handler(context),
  }
  let expander = MacroExpander::make(
    "\\dynamic{xy}",
    Settings::default(),
    dynamic_macros=dynamic,
  )
  assert_eq(expanded_text(expander), "xy")
}

///|
test "MacroExpander static definition overrides dynamic builtin" {
  let settings = Settings::default()
  settings.macros["\\mode"] = MacroDefinition::text("S")
  let dynamic : Map[String, MacroHandler] = {
    "\\mode": context => mode_handler(context),
  }
  let expander = MacroExpander::make("\\mode", settings, dynamic_macros=dynamic)
  assert_eq(expanded_text(expander), "S")
}

///|
test "MacroExpander switch_mode and feed preserve macro state" {
  let dynamic : Map[String, MacroHandler] = {
    "\\mode": context => mode_handler(context),
  }
  let expander = MacroExpander::make(
    "\\mode",
    Settings::default(),
    dynamic_macros=dynamic,
  )
  assert_eq(expander.expand_next_token().text, "M")
  assert_eq(expander.expand_next_token().text, "EOF")
  expander.switch_mode(Text)
  expander.feed("\\mode")
  assert_eq(expander.expand_next_token().text, "T")
}

///|
test "MacroExpander feed preserves already stacked tokens" {
  let expander = MacroExpander::make("x", Settings::default())
  assert_eq(expander.future().text, "x")
  expander.feed("y")
  assert_eq(expander.pop_token().text, "x")
  assert_eq(expander.pop_token().text, "y")
}

///|
test "MacroExpander expand_after_future expands exactly once" {
  let settings = Settings::default()
  settings.macros["\\a"] = MacroDefinition::text("\\b")
  settings.macros["\\b"] = MacroDefinition::text("x")
  let expander = MacroExpander::make("\\a", settings)
  assert_eq(expander.expand_after_future().text, "\\b")
  assert_eq(expander.expand_next_token().text, "x")
}

///|
test "MacroExpander expand_once reports expansion token count including zero" {
  let settings = Settings::default()
  settings.macros["\\empty"] = MacroDefinition::text("")
  settings.macros["\\two"] = MacroDefinition::text("xy")
  let empty = MacroExpander::make("\\empty", settings)
  match empty.expand_once() {
    Expanded(count) => assert_eq(count, 0)
    _ => fail("expected empty expansion")
  }
  assert_eq(empty.expand_next_token().text, "EOF")

  let two_settings = Settings::default()
  two_settings.macros["\\two"] = MacroDefinition::text("xy")
  let two = MacroExpander::make("\\two", two_settings)
  match two.expand_once() {
    Expanded(count) => assert_eq(count, 2)
    _ => fail("expected two-token expansion")
  }
}

///|
test "MacroExpander expand_macro and expand_macro_as_text fully expand" {
  let settings = Settings::default()
  settings.macros["\\a"] = MacroDefinition::text("x\\b")
  settings.macros["\\b"] = MacroDefinition::text("y")
  let expander = MacroExpander::make("", settings)
  let tokens = expander.expand_macro("\\a").unwrap()
  assert_eq([tokens[0].text, tokens[1].text], ["x", "y"])
  assert_eq(expander.expand_macro_as_text("\\a"), Some("xy"))
  assert_true(expander.expand_macro("\\missing") is None)
}

///|
test "MacroExpander expand_macro includes dynamic definitions" {
  let dynamic : Map[String, MacroHandler] = {
    "\\mode": context => mode_handler(context),
  }
  let expander = MacroExpander::make(
    "",
    Settings::default(),
    dynamic_macros=dynamic,
  )
  assert_eq(expander.expand_macro_as_text("\\mode"), Some("M"))
}

///|
test "MacroExpander expand_tokens accepts reverse input and returns forward output" {
  let settings = Settings::default()
  settings.macros["\\a"] = MacroDefinition::text("xy")
  let expander = MacroExpander::make("", settings)
  let input = expander.lex_macro_body("a\\a").tokens
  let output = expander.expand_tokens(input)
  assert_eq([output[0].text, output[1].text, output[2].text], ["a", "x", "y"])
}

///|
test "MacroExpander enforces max_expand on recursive expansion" {
  let settings = settings_with_max_expand(2)
  settings.macros["\\loop"] = MacroDefinition::text("\\loop")
  let expander = MacroExpander::make("\\loop", settings)
  match capture_parse_result(() => expander.expand_next_token()) {
    Err(TooManyExpansions(limit~)) => assert_eq(limit, 2)
    _ => fail("expected TooManyExpansions")
  }
}

///|
test "MacroExpander counts expand_tokens output against max_expand" {
  let expander = MacroExpander::make("", settings_with_max_expand(0))
  let input = expander.lex_macro_body("x").tokens
  match capture_parse_result(() => expander.expand_tokens(input)) {
    Err(TooManyExpansions(limit~)) => assert_eq(limit, 0)
    _ => fail("expected output expansion limit")
  }
}

///|
test "MacroExpander noexpand treats expandable token as relax for parser" {
  let settings = Settings::default()
  settings.macros["\\foo"] = MacroDefinition::text("x")
  let dynamic : Map[String, MacroHandler] = { "\\noexpand": noexpand_handler }
  let expander = MacroExpander::make(
    "\\noexpand\\foo",
    settings,
    dynamic_macros=dynamic,
  )
  assert_eq(expander.expand_next_token().text, "\\relax")
}

///|
test "MacroExpander noexpand leaves non-expandable token unchanged" {
  let dynamic : Map[String, MacroHandler] = { "\\noexpand": noexpand_handler }
  let expander = MacroExpander::make(
    "\\noexpand x",
    Settings::default(),
    dynamic_macros=dynamic,
  )
  assert_eq(expander.expand_next_token().text, "x")
}

///|
test "MacroExpander expand_tokens preserves noexpand token and clears flags" {
  let settings = Settings::default()
  settings.macros["\\foo"] = MacroDefinition::text("x")
  let dynamic : Map[String, MacroHandler] = { "\\noexpand": noexpand_handler }
  let expander = MacroExpander::make("", settings, dynamic_macros=dynamic)
  let input = expander.lex_macro_body("\\noexpand\\foo").tokens
  let output = expander.expand_tokens(input)
  assert_eq(output.length(), 1)
  assert_eq(output[0].text, "\\foo")
  assert_false(output[0].noexpand)
  assert_false(output[0].treat_as_relax)
}

///|
test "MacroExpander respects unexpandable expansion in expandable-only mode" {
  let settings = Settings::default()
  settings.macros["\\alias"] = MacroDefinition::expansion(
    make_macro_expansion("x", unexpandable=true),
  )
  let expander = MacroExpander::make("\\alias", settings)
  assert_false(expander.is_expandable("\\alias"))
  let input = expander.lex_macro_body("\\alias").tokens
  let output = expander.expand_tokens(input)
  assert_eq(output[0].text, "\\alias")
  assert_eq(expander.expand_next_token().text, "x")
}

///|
test "MacroExpander uses active-character catcode for single-character macros" {
  let settings = Settings::default()
  settings.macros["~"] = MacroDefinition::text("x")
  let active = MacroExpander::make("~", settings)
  assert_eq(active.expand_next_token().text, "x")

  let inactive_settings = Settings::default()
  inactive_settings.macros["~"] = MacroDefinition::text("x")
  let inactive = MacroExpander::make("~", inactive_settings)
  inactive.lexer.set_catcode("~", 12)
  assert_eq(inactive.expand_next_token().text, "~")
}

///|
test "MacroExpander command resolver drives defined and expandable checks" {
  let expander = MacroExpander::make(
    "",
    Settings::default(),
    command_status=test_command_status,
  )
  assert_true(expander.is_defined("\\expandable"))
  assert_true(expander.is_expandable("\\expandable"))
  assert_true(expander.is_defined("\\primitive"))
  assert_false(expander.is_expandable("\\primitive"))
  assert_false(expander.is_defined("\\missing"))
  assert_true(expander.is_defined("^"))
}

///|
test "MacroExpander expandable-only expansion rejects undefined control sequence" {
  let expander = MacroExpander::make("\\missing", Settings::default())
  match capture_parse_result(() => expander.expand_once(expandable_only=true)) {
    Err(UndefinedControlSequence(name~, loc~)) => {
      assert_eq(name, "\\missing")
      assert_eq(loc, None)
    }
    _ => fail("expected UndefinedControlSequence")
  }
}

///|
test "MacroExpander global macro changes persist in settings map" {
  let settings = Settings::default()
  let expander = MacroExpander::make("", settings)
  expander.macros.set("\\global", Some(MacroDefinition::text("x")), global=true)
  assert_true(settings.macros.contains("\\global"))
  assert_eq(expander.expand_macro_as_text("\\global"), Some("x"))
}
