///|
fn all_control_sequences_are_unexpandable(
  name : String,
) -> ExternalCommandStatus {
  if name.length() > 0 && name[0] == '\\' {
    ExternalUnexpandable
  } else {
    ExternalUndefined
  }
}

///|
test "builtin registry contains every static and dynamic KaTeX macro" {
  assert_eq(builtin_static_macros().length(), 313)
  assert_eq(builtin_dynamic_macros().length(), 20)
  assert_eq(
    builtin_static_macros().get("\\LaTeX"),
    Some(
      MacroDefinition::text(
        "\\textrm{\\html@mathml{L\\kern-.36em\\raisebox{0.205em}{\\scriptstyle A}\\kern-.15em\\TeX}{LaTeX}}",
      ),
    ),
  )
  assert_true(builtin_dynamic_macros().contains("\\bra@ket"))
}

///|
test "builtin expansion controls preserve TeX token ordering" {
  let settings = Settings::default()
  settings.macros["\\foo"] = MacroDefinition::text("x")
  settings.macros["\\bar"] = MacroDefinition::text("y")
  assert_eq(
    expanded_text(MacroExpander::make("\\expandafter\\foo\\bar", settings)),
    "xy",
  )
  assert_eq(
    expanded_text(MacroExpander::make("\\noexpand\\foo", settings)),
    "\\relax",
  )
  assert_eq(
    expanded_text(
      MacroExpander::make("\\@firstoftwo{a}{b}\\@secondoftwo{c}{d}", settings),
    ),
    "ad",
  )
  assert_eq(
    expanded_text(MacroExpander::make("\\@ifnextchar*{a}{b}   *", settings)),
    "a*",
  )
  assert_eq(
    expanded_text(MacroExpander::make("\\@ifnextchar*{a}{b}x", settings)),
    "bx",
  )
}

///|
test "local dynamic macros override unexpandable static definitions" {
  let settings = Settings::default()
  settings.macros["\\x"] = MacroDefinition::expansion(
    make_macro_expansion("s", unexpandable=true),
  )
  let expander = MacroExpander::make("", settings)
  assert_false(expander.is_expandable("\\x"))
  expander.dynamic_macros.begin_group()
  expander.dynamic_macros.set("\\x", Some(context => mode_handler(context)))
  assert_true(expander.is_expandable("\\x"))
  expander.dynamic_macros.end_group()
  assert_false(expander.is_expandable("\\x"))
}

///|
test "TextOrMath selects the current expander mode" {
  assert_eq(
    expanded_text(
      MacroExpander::make("\\TextOrMath{T}{M}", Settings::default()),
    ),
    "M",
  )
  assert_eq(
    expanded_text(
      MacroExpander::make("\\TextOrMath{T}{M}", Settings::default(), mode=Text),
    ),
    "T",
  )
}

///|
test "char accepts decimal octal hexadecimal and backtick forms" {
  assert_eq(
    expanded_text(
      MacroExpander::make(
        "\\char37,\\char'45,\\char\"25,\\char`\\%,\\char\"1d7d9",
        Settings::default(),
      ),
    ),
    "\\@char{37},\\@char{37},\\@char{37},\\@char{37},\\@char{120793}",
  )
}

///|
test "char rejects missing and invalid digits" {
  match
    capture_parse_result(() => {
      MacroExpander::make("\\char'8", Settings::default()).expand_next_token()
    }) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "Invalid base-8 digit 8")
    _ => fail("expected invalid octal digit")
  }
  match
    capture_parse_result(() => {
      MacroExpander::make("\\char`", Settings::default()).expand_next_token()
    }) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "\\char` missing argument")
    _ => fail("expected missing backtick argument")
  }
}

///|
test "newcommand renewcommand and providecommand implement scoped definitions" {
  let expander = MacroExpander::make(
    "\\newcommand\\foo[2]{#2#1}\\foo ab",
    Settings::default(),
  )
  expander.begin_group()
  assert_eq(expanded_text(expander), "ba")
  expander.end_group()
  expander.feed("\\foo")
  assert_eq(expanded_text(expander), "\\foo")

  let replacement = MacroExpander::make(
    "\\newcommand\\foo{a}\\renewcommand\\foo{b}\\providecommand\\foo{c}\\foo",
    Settings::default(),
  )
  assert_eq(expanded_text(replacement), "b")
}

///|
test "newcommand validates existence and argument count" {
  match
    capture_parse_result(() => {
      MacroExpander::make("\\newcommand\\lambda{x}", Settings::default()).expand_next_token()
    }) {
    Err(InvalidArgument(message~, ..)) =>
      assert_true(starts_with_at(message, 0, "\\newcommand"))
    _ => fail("expected redefinition error")
  }
  match
    capture_parse_result(() => {
      MacroExpander::make("\\newcommand\\foo[1.5]{x}", Settings::default()).expand_next_token()
    }) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "Invalid number of arguments: 1.5")
    _ => fail("expected invalid argument count")
  }
}

///|
test "terminal macros report messages and expand to nothing" {
  let events : Array[MacroLogEvent] = []
  let reporter = fn(event) { events.push(event) }
  let expander = MacroExpander::make(
    "\\message{abc}\\errmessage{def}\\show\\missing x",
    Settings::default(),
    macro_reporter=reporter,
  )
  assert_eq(expanded_text(expander), "x")
  match events {
    [MacroMessage("abc"), MacroErrorMessage("def"), MacroShow(show)] =>
      assert_eq(show, "\\missing: undefined")
    _ => fail("unexpected macro log events")
  }
}

///|
test "dots selects comma binary relation integral and punctuation forms" {
  assert_eq(
    expanded_text(
      MacroExpander::make(
        "\\dots,\\dots\\pm\\dots\\leq\\dots\\int\\dotso)\\dotsc,\\cdots;",
        Settings::default(),
      ),
    ),
    "\\ldots,\\@cdots\\pm\\@cdots\\leq\\mskip-3mu\\relax\\@cdots\\int\\ldots\\mskip+3mu\\relax)\\ldots,\\@cdots\\mskip+3mu\\relax;",
  )
}

///|
test "tag literal rejects a second tag definition" {
  let settings = Settings::default()
  settings.macros["\\df@tag"] = MacroDefinition::text("x")
  match
    capture_parse_result(() => {
      MacroExpander::make("\\tag@literal{x}", settings).expand_next_token()
    }) {
    Err(InvalidArgument(message~, ..)) => assert_eq(message, "Multiple \\tag")
    _ => fail("expected duplicate tag error")
  }
}

///|
test "Braket expands separators and restores previous bindings" {
  let settings = Settings::default()
  settings.macros["|"] = MacroDefinition::text("X")
  let expander = MacroExpander::make(
    "\\Braket{a|b||c}|",
    settings,
    command_status=all_control_sequences_are_unexpandable,
  )
  assert_eq(
    expanded_text(expander),
    "\\left\\langlea\\mskip+3mu\\relax\\middle\\vert\\mskip+3mu\\relaxb\\mskip+3mu\\relax\\middle\\vert\\mskip+3mu\\relaxc\\right\\rangleX",
  )
}

///|
test "Set only replaces the first separator" {
  let expander = MacroExpander::make(
    "\\Set{x|x>0|x<1}",
    Settings::default(),
    command_status=all_control_sequences_are_unexpandable,
  )
  assert_eq(
    expanded_text(expander),
    "\\left\\{\\mskip+4mu\\relaxx\\mskip+5mu\\relax\\middle\\vert\\mskip+5mu\\relaxx>0|x<1\\mskip+4mu\\relax\\right\\}",
  )
}

///|
test "Braket closes temporary bindings when its argument raises" {
  let expander = MacroExpander::make(
    "\\Braket{a",
    Settings::default(),
    command_status=all_control_sequences_are_unexpandable,
  )
  match capture_parse_result(() => expander.expand_next_token()) {
    Err(InvalidArgument(..)) => ()
    _ => fail("expected unterminated Braket argument")
  }
  assert_true(expander.macros.undo_stack.is_empty())
  assert_true(expander.dynamic_macros.undo_stack.is_empty())
  assert_true(expander.dynamic_macros.get_current("|") is None)
  assert_true(expander.dynamic_macros.get_current("\\|") is None)
}
