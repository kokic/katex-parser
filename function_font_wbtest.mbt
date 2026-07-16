///|
test "font commands map aliases and normalize single-node arguments" {
  let cases : Array[(String, String)] = [
    ("\\mathrm", "mathrm"),
    ("\\mathit", "mathit"),
    ("\\mathbf", "mathbf"),
    ("\\mathnormal", "mathnormal"),
    ("\\mathsfit", "mathsfit"),
    ("\\mathbb", "mathbb"),
    ("\\mathcal", "mathcal"),
    ("\\mathfrak", "mathfrak"),
    ("\\mathscr", "mathscr"),
    ("\\mathsf", "mathsf"),
    ("\\mathtt", "mathtt"),
    ("\\Bbb", "mathbb"),
    ("\\bold", "mathbf"),
    ("\\frak", "mathfrak"),
  ]
  for item in cases {
    let (command, expected) = item
    guard parse(command + "{x}")
      is [Font(mode=Math, font~, body=MathOrd(text="x", ..))] else {
      fail("unexpected font AST")
    }
    assert_eq(font, expected)
  }
  assert_true(
    parse("\\mathbf{xy}")
    is [
      Font(
        font="mathbf",
        body=OrdGroup(body=[MathOrd(text="x", ..), MathOrd(text="y", ..)], ..),
        ..
      ),
    ],
  )
}

///|
test "font commands are valid unbraced script arguments" {
  assert_true(
    parse("x^\\mathbf y")
    is [
      SupSub(sup=Some(Font(font="mathbf", body=MathOrd(text="y", ..), ..)), ..),
    ],
  )
}

///|
test "boldsymbol inherits binrel class and character-box status" {
  assert_true(
    parse("\\boldsymbol{+}\\bm{=}")
    is [
      MClass(
        mclass=Mbin,
        body=[Font(font="boldsymbol", ..)],
        is_character_box=true,
        ..
      ),
      MClass(
        mclass=Mrel,
        body=[Font(font="boldsymbol", ..)],
        is_character_box=true,
        ..
      ),
    ],
  )
  assert_true(
    parse("\\boldsymbol{xy}")
    is [MClass(mclass=Mord, is_character_box=false, ..)],
  )
  assert_true(
    parse("\\boldsymbol{\\textcolor{red}{x}}")
    is [MClass(mclass=Mord, is_character_box=true, ..)],
  )
}

///|
test "old-style font commands consume their current expression" {
  assert_true(
    parse("{\\bf x}y")
    is [
      OrdGroup(
        body=[
          Font(
            mode=Math,
            font="mathbf",
            body=OrdGroup(body=[MathOrd(text="x", ..)], ..)
          ),
        ],
        ..
      ),
      MathOrd(text="y", ..),
    ],
  )
  assert_true(
    parse("\\text{\\it a b}")
    is [
      Text(
        body=[
          Font(
            mode=Text,
            font="mathit",
            body=OrdGroup(
              body=[TextOrd(text="a", ..), Spacing(..), TextOrd(text="b", ..)],
              ..
            )
          ),
        ],
        ..
      ),
    ],
  )
}

///|
test "old-style font commands stop before infix operators" {
  assert_true(
    parse("a\\bf b\\over c")
    is [
      GenFrac(
        numer=OrdGroup(
          body=[
            MathOrd(text="a", ..),
            Font(
              font="mathbf",
              body=OrdGroup(body=[MathOrd(text="b", ..)], ..),
              ..
            ),
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
test "font registry specs match KaTeX permissions" {
  let font = require_function(builtin_function_registry, "\\mathbf")
  assert_eq(font.names.length(), 14)
  assert_eq(font.num_args, 1)
  assert_true(font.allowed_in_argument)
  assert_false(font.allowed_in_text)
  let boldsymbol = require_function(builtin_function_registry, "\\boldsymbol")
  assert_eq(boldsymbol.names.length(), 2)
  assert_false(boldsymbol.allowed_in_argument)
  assert_false(boldsymbol.allowed_in_text)
  let old_font = require_function(builtin_function_registry, "\\bf")
  assert_eq(old_font.names.length(), 6)
  assert_eq(old_font.num_args, 0)
  assert_true(old_font.allowed_in_text)
  assert_false(old_font.allowed_in_argument)
}
