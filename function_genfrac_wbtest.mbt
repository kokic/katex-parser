///|
test "standard fraction aliases preserve style and continued flags" {
  assert_true(
    parse("\\frac12")
    is [
      GenFrac(
        numer=OrdGroup(body=[TextOrd(text="1", ..)], ..),
        denom=OrdGroup(body=[TextOrd(text="2", ..)], ..),
        continued=false,
        has_bar_line=true,
        bar_size=None,
        left_delim=None,
        right_delim=None,
        ..
      ),
    ],
  )
  assert_true(
    parse("\\cfrac12")
    is [
      Styling(
        style=DisplayStyle,
        reset_font=false,
        body=[GenFrac(continued=true, has_bar_line=true, ..)],
        ..
      ),
    ],
  )
  assert_true(
    parse("\\dfrac12")
    is [Styling(style=DisplayStyle, body=[GenFrac(continued=false, ..)], ..)],
  )
  assert_true(
    parse("\\tfrac12")
    is [Styling(style=TextStyle, body=[GenFrac(continued=false, ..)], ..)],
  )
}

///|
test "binomial aliases omit the bar and select delimiters" {
  assert_true(
    parse("\\binom12")
    is [
      GenFrac(
        has_bar_line=false,
        left_delim=Some("("),
        right_delim=Some(")"),
        ..
      ),
    ],
  )
  assert_true(
    parse("\\dbinom12")
    is [
      Styling(
        style=DisplayStyle,
        body=[GenFrac(has_bar_line=false, left_delim=Some("("), ..)],
        ..
      ),
    ],
  )
  assert_true(
    parse("\\tbinom12")
    is [Styling(style=TextStyle, body=[GenFrac(has_bar_line=false, ..)], ..)],
  )
}

///|
test "infix fraction aliases rewrite the surrounding expression" {
  let cases : Array[(String, String?, String?, Bool)] = [
    ("a\\over b", None, None, true),
    ("a\\choose b", Some("("), Some(")"), false),
    ("a\\atop b", None, None, false),
    ("a\\brace b", Some("\\{"), Some("\\}"), false),
    ("a\\brack b", Some("["), Some("]"), false),
  ]
  for item in cases {
    let (input, left, right, has_bar_line) = item
    guard parse(input)
      is [
        GenFrac(
          numer=OrdGroup(body=[MathOrd(text="a", ..)], ..),
          denom=OrdGroup(body=[MathOrd(text="b", ..)], ..),
          left_delim=actual_left,
          right_delim=actual_right,
          has_bar_line=actual_bar,
          ..
        ),
      ] else {
      fail("unexpected infix fraction AST")
    }
    assert_eq(actual_left, left)
    assert_eq(actual_right, right)
    assert_eq(actual_bar, has_bar_line)
  }
}

///|
test "infix fractions respect group boundaries and reject ambiguity" {
  assert_true(
    parse("{a\\over b}\\over c")
    is [
      GenFrac(
        numer=OrdGroup(body=[GenFrac(..)], ..),
        denom=OrdGroup(body=[MathOrd(text="c", ..)], ..),
        ..
      ),
    ],
  )
  match capture_parse_result(() => parse("a\\over b\\over c")) {
    Err(InvalidArgument(message~, loc=Some(_))) =>
      assert_eq(message, "only one infix operator per group")
    _ => fail("expected duplicate infix error")
  }
  assert_true(
    parse("\\over x")
    is [
      GenFrac(
        numer=OrdGroup(body=[], ..),
        denom=OrdGroup(body=[MathOrd(text="x", ..)], ..),
        ..
      ),
    ],
  )
  assert_true(
    parse("1\\over")
    is [
      GenFrac(
        numer=OrdGroup(body=[TextOrd(text="1", ..)], ..),
        denom=OrdGroup(body=[], ..),
        ..
      ),
    ],
  )
}

///|
test "above uses its parsed size as the fraction bar" {
  assert_true(
    parse("a\\above1pt b")
    is [
      GenFrac(
        has_bar_line=true,
        bar_size=Some({ number: 1.0, unit: "pt" }),
        left_delim=None,
        right_delim=None,
        ..
      ),
    ],
  )
  assert_true(
    parse("a\\above0pt b")
    is [
      GenFrac(
        has_bar_line=false,
        bar_size=Some({ number: 0.0, unit: "pt" }),
        ..
      ),
    ],
  )
}

///|
test "genfrac interprets delimiters bar size and style arguments" {
  assert_true(
    parse("\\genfrac{(}{)}{}{0}{a}{b}")
    is [
      Styling(
        style=DisplayStyle,
        reset_font=false,
        body=[
          GenFrac(
            numer=OrdGroup(body=[MathOrd(text="a", ..)], ..),
            denom=OrdGroup(body=[MathOrd(text="b", ..)], ..),
            has_bar_line=true,
            bar_size=None,
            left_delim=Some("("),
            right_delim=Some(")"),
            ..
          ),
        ],
        ..
      ),
    ],
  )
  assert_true(
    parse("\\genfrac{.}{.}{0pt}{3}{a}{b}")
    is [
      Styling(
        style=ScriptScriptStyle,
        body=[
          GenFrac(
            has_bar_line=false,
            bar_size=Some({ number: 0.0, unit: "pt" }),
            left_delim=None,
            right_delim=None,
            ..
          ),
        ],
        ..
      ),
    ],
  )
  assert_true(
    parse("\\genfrac{[}{]}{2pt}{}{a}{b}")
    is [
      GenFrac(
        has_bar_line=true,
        bar_size=Some({ number: 2.0, unit: "pt" }),
        left_delim=Some("["),
        right_delim=Some("]"),
        ..
      ),
    ],
  )
  assert_true(
    parse("\\genfrac ( ] {0.06em}{0}{a}{b+c}")
    is [
      Styling(
        style=DisplayStyle,
        body=[
          GenFrac(
            has_bar_line=true,
            bar_size=Some({ number: 0.06, unit: "em" }),
            left_delim=Some("("),
            right_delim=Some("]"),
            denom=OrdGroup(
              body=[
                MathOrd(text="b", ..),
                Atom(text="+", ..),
                MathOrd(text="c", ..),
              ],
              ..
            ),
            ..
          ),
        ],
        ..
      ),
    ],
  )
}

///|
test "break_on_infix returns the higher-precedence prefix without consuming" {
  let parser = Parser::make("a\\over b", Settings::default())
  assert_true(parser.parse_expression(true, None) is [MathOrd(text="a", ..)])
  assert_eq(parser.fetch().text, "\\over")
}

///|
test "fraction functions are valid superscript arguments" {
  assert_true(
    parse("x^\\frac12")
    is [SupSub(sup=Some(GenFrac(has_bar_line=true, ..)), ..)],
  )
  match capture_parse_result(() => parse("\\sqrt\\over2")) {
    Err(
      FunctionNotAllowed(func_name="\\over", context="argument to '\\sqrt'", ..)
    ) => ()
    _ => fail("expected infix rejection in primitive sqrt body")
  }
}

///|
test "genfrac registry contains every direct and infix alias" {
  for
    name in [
      "\\cfrac", "\\dfrac", "\\frac", "\\tfrac", "\\dbinom", "\\binom", "\\tbinom",
      "\\over", "\\choose", "\\atop", "\\brace", "\\brack", "\\genfrac", "\\above",
    ] {
    assert_true(lookup_function(name) is Some(_))
  }
  assert_true(require_function(builtin_function_registry, "\\over").infix)
  assert_true(require_function(builtin_function_registry, "\\above").infix)
  assert_true(
    require_function(builtin_function_registry, "\\frac").allowed_in_argument,
  )
}
