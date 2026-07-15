///|
test "text parses its body in text mode and preserves spaces" {
  assert_true(
    parse("\\text{a b}")
    is [
      Text(
        mode=Math,
        font="\\text",
        body=[
          TextOrd(mode=Text, text="a", ..),
          Spacing(mode=Text, text=" ", ..),
          TextOrd(mode=Text, text="b", ..),
        ]
      ),
    ],
  )
}

///|
test "every text alias records its original font command" {
  for
    name in [
      "\\text", "\\textrm", "\\textsf", "\\texttt", "\\textnormal", "\\textbf", "\\textmd",
      "\\textit", "\\textup", "\\emph",
    ] {
    guard parse(name + "{x}") is [Text(font~, body=[TextOrd(text="x", ..)], ..)] else {
      fail("unexpected text alias AST")
    }
    assert_eq(font, name)
  }
}

///|
test "text aliases nest and are valid script arguments" {
  assert_true(
    parse("\\text{a\\textbf{b}c}")
    is [
      Text(
        font="\\text",
        body=[
          TextOrd(text="a", ..),
          Text(font="\\textbf", body=[TextOrd(text="b", ..)], ..),
          TextOrd(text="c", ..),
        ],
        ..
      ),
    ],
  )
  assert_true(
    parse("x^\\text{a}") is [SupSub(sup=Some(Text(font="\\text", ..)), ..)],
  )
}

///|
test "text mode forms KaTeX ASCII ligatures with exact ranges" {
  let input = "\\text{-- --- `` ''}"
  guard parse(input)
    is [
      Text(
        body=[
          TextOrd(text="--", loc=double_dash_loc, ..),
          Spacing(..),
          TextOrd(text="---", loc=triple_dash_loc, ..),
          Spacing(..),
          TextOrd(text="``", ..),
          Spacing(..),
          TextOrd(text="''", ..),
        ],
        ..
      ),
    ] else {
    fail("unexpected text ligature AST")
  }
  assert_eq(double_dash_loc, Some(SourceLocation::make(input, start=6, end=8)))
  assert_eq(triple_dash_loc, Some(SourceLocation::make(input, start=9, end=12)))
}

///|
test "text ligatures are greedy and do not cross non-textord nodes" {
  assert_true(
    parse("\\text{-----}")
    is [Text(body=[TextOrd(text="---", ..), TextOrd(text="--", ..)], ..)],
  )
  assert_true(
    parse("\\text{-{x}-}")
    is [
      Text(
        body=[
          TextOrd(text="-", ..),
          OrdGroup(body=[TextOrd(text="x", ..)], ..),
          TextOrd(text="-", ..),
        ],
        ..
      ),
    ],
  )
  assert_eq(parse("--").length(), 2)
}

///|
test "text ligatures do not fabricate ranges across macro sources" {
  let settings = Settings::default()
  settings.macros["\\dash"] = MacroDefinition::text("-")
  assert_true(
    parse("\\text{\\dash-}", settings~)
    is [Text(body=[TextOrd(text="--", loc=None, ..)], ..)],
  )
}

///|
test "text registry spec matches KaTeX permissions" {
  let spec = require_function(builtin_function_registry, "\\text")
  assert_eq(spec.names.length(), 10)
  assert_true(spec.arg_types is [TextArg])
  assert_true(spec.allowed_in_argument)
  assert_true(spec.allowed_in_text)
  assert_true(spec.allowed_in_math)
}
