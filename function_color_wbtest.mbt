///|
test "textcolor parses and flattens its explicit body" {
  assert_true(
    parse("\\textcolor{#fA6}{x+y}")
    is [
      Color(
        mode=Math,
        color="#fA6",
        body=[
          MathOrd(text="x", ..),
          Atom(family=Mbin, text="+", ..),
          MathOrd(text="y", ..),
        ]
      ),
    ],
  )
  assert_true(
    parse("\\textcolor{fA6fA6}{x}")
    is [Color(color="#fA6fA6", body=[MathOrd(text="x", ..)], ..)],
  )
}

///|
test "textcolor is available in text mode without changing the body mode" {
  assert_true(
    parse("\\text{a \\textcolor{red}{b c}}")
    is [
      Text(
        body=[
          TextOrd(text="a", ..),
          Spacing(..),
          Color(
            mode=Text,
            color="red",
            body=[TextOrd(text="b", ..), Spacing(..), TextOrd(text="c", ..)]
          ),
        ],
        ..
      ),
    ],
  )
}

///|
test "color consumes the remaining expression in its current group" {
  assert_true(
    parse("\\color{#fA6}xy")
    is [
      Color(
        mode=Math,
        color="#fA6",
        body=[MathOrd(text="x", ..), MathOrd(text="y", ..)]
      ),
    ],
  )
  assert_true(
    parse("{\\color{red}x}y")
    is [
      OrdGroup(body=[Color(color="red", body=[MathOrd(text="x", ..)], ..)], ..),
      MathOrd(text="y", ..),
    ],
  )
}

///|
test "color stops its implicit body before an infix operator" {
  assert_true(
    parse("a\\color{red}b\\over c")
    is [
      GenFrac(
        numer=OrdGroup(
          body=[
            MathOrd(text="a", ..),
            Color(color="red", body=[MathOrd(text="b", ..)], ..),
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
test "color stores the normalized current color in the active namespace" {
  let settings : Settings = {
    throw_on_error: true,
    error_color: "#cc0000",
    color_is_text_color: false,
    max_expand: 1000,
    global_group: true,
    macros: Map([]),
  }
  let parser = Parser::make("\\color{fA6fA6}x", settings)
  assert_true(
    parser.parse() is [Color(color="#fA6fA6", body=[MathOrd(text="x", ..)], ..)],
  )
  assert_eq(
    parser.gullet.macros.get_current("\\current@color"),
    Some(MacroDefinition::text("#fA6fA6")),
  )
}

///|
test "colorIsTextColor aliases color only for the current public parse" {
  let settings : Settings = {
    throw_on_error: true,
    error_color: "#cc0000",
    color_is_text_color: true,
    max_expand: 1000,
    global_group: true,
    macros: Map([]),
  }
  assert_true(
    parse("\\color{red}{x}y", settings~)
    is [
      Color(color="red", body=[MathOrd(text="x", ..)], ..),
      MathOrd(text="y", ..),
    ],
  )
  assert_eq(settings.macros.get("\\color"), None)
  assert_eq(settings.macros.get("\\current@color"), None)
}

///|
test "builtin color macros expand through textcolor" {
  assert_true(
    parse("\\blue{x}\\redA{y}")
    is [
      Color(color="#6495ed", body=[MathOrd(text="x", ..)], ..),
      Color(color="#fca9a9", body=[MathOrd(text="y", ..)], ..),
    ],
  )
}

///|
test "color registry specs match KaTeX permissions and argument types" {
  let textcolor = require_function(builtin_function_registry, "\\textcolor")
  assert_true(textcolor.arg_types is [ColorArg, OriginalArg])
  assert_true(textcolor.allowed_in_text)
  assert_true(textcolor.allowed_in_math)
  assert_false(textcolor.allowed_in_argument)
  let color = require_function(builtin_function_registry, "\\color")
  assert_true(color.arg_types is [ColorArg])
  assert_true(color.allowed_in_text)
  assert_true(color.allowed_in_math)
  assert_false(color.allowed_in_argument)
}
