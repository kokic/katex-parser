///|
test "styling commands map to typed style levels and implicit bodies" {
  let cases : Array[(String, StyleLevel)] = [
    ("\\displaystyle", DisplayStyle),
    ("\\textstyle", TextStyle),
    ("\\scriptstyle", ScriptStyle),
    ("\\scriptscriptstyle", ScriptScriptStyle),
  ]
  for item in cases {
    let (command, expected) = item
    guard parse(command + " xy")
      is [Styling(mode=Math, body~, style~, reset_font=false)] else {
      fail("unexpected styling AST")
    }
    assert_eq(style, expected)
    assert_true(body is [MathOrd(text="x", ..), MathOrd(text="y", ..)])
  }
}

///|
test "styling commands preserve text mode normalization" {
  assert_true(
    parse("\\text{a \\scriptstyle--}")
    is [
      Text(
        body=[
          TextOrd(text="a", ..),
          Spacing(..),
          Styling(
            mode=Text,
            style=ScriptStyle,
            body=[TextOrd(mode=Text, text="--", ..)],
            reset_font=false
          ),
        ],
        ..
      ),
    ],
  )
}

///|
test "styling commands stop at group and infix boundaries" {
  assert_true(
    parse("{\\textstyle x}y")
    is [
      OrdGroup(
        body=[Styling(style=TextStyle, body=[MathOrd(text="x", ..)], ..)],
        ..
      ),
      MathOrd(text="y", ..),
    ],
  )
  assert_true(
    parse("a\\displaystyle b\\over c")
    is [
      GenFrac(
        numer=OrdGroup(
          body=[
            MathOrd(text="a", ..),
            Styling(style=DisplayStyle, body=[MathOrd(text="b", ..)], ..),
          ],
          ..
        ),
        denom=OrdGroup(body=[MathOrd(text="c", ..)], ..),
        ..
      ),
    ],
  )
}

///|
test "styling registry spec matches KaTeX primitive permissions" {
  for
    command in [
      "\\displaystyle", "\\textstyle", "\\scriptstyle", "\\scriptscriptstyle",
    ] {
    let spec = require_function(builtin_function_registry, command)
    assert_eq(spec.names.length(), 4)
    assert_eq(spec.num_args, 0)
    assert_true(spec.arg_types.is_empty())
    assert_true(spec.allowed_in_text)
    assert_true(spec.allowed_in_math)
    assert_false(spec.allowed_in_argument)
    assert_true(spec.primitive)
    assert_false(spec.is_expandable())
  }
}
