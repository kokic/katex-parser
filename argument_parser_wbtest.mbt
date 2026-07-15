///|
test "parse_string_group preserves optional lookahead and token text" {
  let absent = Parser::make("x", Settings::default())
  assert_true(absent.parse_string_group(true) is None)
  assert_eq(absent.fetch().text, "x")

  let optional = Parser::make("[a b]x", Settings::default())
  guard optional.parse_string_group(true) is Some(token) else {
    fail("expected optional string group")
  }
  assert_eq(token.text, "a b")
  assert_eq(optional.fetch().text, "x")

  let mandatory = Parser::make("{a b}", Settings::default())
  guard mandatory.parse_string_group(false) is Some(group) else {
    fail("expected mandatory string group")
  }
  assert_eq(group.text, "a b")
}

///|
test "color arguments match KaTeX validation and normalization" {
  let cases : Array[(String, String)] = [
    ("{red}", "red"),
    ("{ABCDEF}", "#ABCDEF"),
    ("{#abc}", "#abc"),
    ("{#abcd}", "#abcd"),
    ("{#abcdef}", "#abcdef"),
    ("{#abcdef12}", "#abcdef12"),
  ]
  for item in cases {
    let (input, expected) = item
    let parser = Parser::make(input, Settings::default())
    guard parser.parse_group_of_type("color", ColorArg, false)
      is Some(ColorToken(mode=Math, color~)) else {
      fail("expected color token")
    }
    assert_eq(color, expected)
  }
  for input in ["{#12}", "{1a2}", "{12345}", "{red-1}", "{}"] {
    let parser = Parser::make(input, Settings::default())
    match
      capture_parse_result(() => {
        parser.parse_group_of_type("color", ColorArg, false)
      }) {
      Err(InvalidArgument(message~, ..)) =>
        assert_true(starts_with_at(message, 0, "Invalid color:"))
      _ => fail("expected invalid color")
    }
  }
}

///|
test "raw arguments produce typed text-mode nodes" {
  let parser = Parser::make("{a\\# b}", Settings::default())
  assert_true(
    parser.parse_group_of_type("raw", RawArg, false)
    is Some(Raw(mode=Text, string="a\\# b")),
  )
}

///|
test "size arguments parse braced unbraced optional and blank forms" {
  let braced = Parser::make("{-1.25em}", Settings::default())
  assert_true(
    braced.parse_group_of_type("size", SizeArg, false)
    is Some(
      Size(mode=Math, value={ number: -1.25, unit: "em" }, is_blank=false)
    ),
  )

  let unbraced = Parser::make(".5em x", Settings::default())
  assert_true(
    unbraced.parse_group_of_type("size", SizeArg, false)
    is Some(Size(mode=Math, value={ number: 0.5, unit: "em" }, is_blank=false)),
  )
  assert_eq(unbraced.fetch().text, "x")

  let blank = Parser::make("{}", Settings::default())
  assert_true(
    blank.parse_group_of_type("size", SizeArg, false)
    is Some(Size(mode=Math, value={ number: 0.0, unit: "pt" }, is_blank=true)),
  )

  let optional = Parser::make("[2mu]x", Settings::default())
  assert_true(
    optional.parse_group_of_type("size", SizeArg, true)
    is Some(Size(mode=Math, value={ number: 2.0, unit: "mu" }, is_blank=false)),
  )
  assert_eq(optional.fetch().text, "x")
}

///|
test "size arguments reject invalid syntax and units" {
  for
    item in [
      ("{.em}", "Invalid size: '.em'"),
      ("{0}", "Invalid size: '0'"),
      ("{em}", "Invalid size: 'em'"),
      ("{1au}", "Invalid unit: 'au'"),
      ("{1zz}", "Invalid unit: 'zz'"),
    ] {
    let (input, expected) = item
    let parser = Parser::make(input, Settings::default())
    match
      capture_parse_result(() => {
        parser.parse_group_of_type("size", SizeArg, false)
      }) {
      Err(InvalidArgument(message~, ..)) => assert_eq(message, expected)
      _ => fail("expected invalid size")
    }
  }
  assert_eq(
    parse_size_measurement("junk- 1.5emtail"),
    Some({ number: -1.5, unit: "em" }),
  )
  for text in ["", "+", "+ ", ".", ".5", "1.", "1. em", "1em "] {
    assert_true(size_scan_candidate(text))
  }
  for text in ["a", "1ema", "1 e m", ".."] {
    assert_false(size_scan_candidate(text))
  }
  for
    unit in [
      "pt", "mm", "cm", "in", "bp", "pc", "dd", "cc", "nd", "nc", "sp", "px", "ex",
      "em", "mu",
    ] {
    assert_true(valid_size_unit(unit))
  }
  assert_false(valid_size_unit("au"))
}

///|
test "URL arguments unescape TeX specials and restore lexer catcodes" {
  let parser = Parser::make("{a\\#b\\%c~d}", Settings::default())
  assert_true(
    parser.parse_group_of_type("url", UrlArg, false)
    is Some(Url(mode=Math, url="a#b%c~d")),
  )
  assert_eq(parser.gullet.lexer.catcode("%"), Some(14))
  assert_eq(parser.gullet.lexer.catcode("~"), Some(13))
  assert_eq(unescape_url("😀\\#x"), "😀#x")

  let malformed = Parser::make("{a", Settings::default())
  match
    capture_parse_result(() => {
      malformed.parse_group_of_type("url", UrlArg, false)
    }) {
    Err(InvalidArgument(..)) => ()
    _ => fail("expected unterminated URL argument")
  }
  assert_eq(malformed.gullet.lexer.catcode("%"), Some(14))
  assert_eq(malformed.gullet.lexer.catcode("~"), Some(13))
}

///|
test "mode-changing and hbox arguments restore the outer parser mode" {
  let text = Parser::make("{xy}", Settings::default())
  assert_true(
    text.parse_group_of_type("text", TextArg, false)
    is Some(
      OrdGroup(
        mode=Text,
        body=[
          TextOrd(mode=Text, text="x", ..),
          TextOrd(mode=Text, text="y", ..),
        ],
        ..
      )
    ),
  )
  assert_eq(text.mode, Math)
  assert_eq(text.gullet.mode, Math)

  let hbox = Parser::make("{x}", Settings::default())
  assert_true(
    hbox.parse_group_of_type("hbox", HboxArg, false)
    is Some(
      Styling(
        mode=Text,
        style=TextStyle,
        reset_font=true,
        body=[OrdGroup(mode=Text, body=[TextOrd(mode=Text, text="x", ..)], ..)]
      )
    ),
  )
  assert_eq(hbox.mode, Math)

  let failing = Parser::make("{\\missing}", Settings::default())
  match
    capture_parse_result(() => {
      failing.parse_group_of_type("text", TextArg, false)
    }) {
    Err(UndefinedControlSequence(..)) => ()
    _ => fail("expected text argument error")
  }
  assert_eq(failing.mode, Math)
  assert_eq(failing.gullet.mode, Math)
  assert_true(failing.gullet.macros.undo_stack.is_empty())
}

///|
test "primitive arguments preserve internal nodes and reject optional use" {
  let parser = Parser::make("\\relax x", Settings::default())
  assert_true(
    parser.parse_group_of_type("primitive", PrimitiveArg, false)
    is Some(Internal(mode=Math)),
  )
  parser.consume_spaces()
  assert_eq(parser.fetch().text, "x")

  let optional = Parser::make("[x]", Settings::default())
  match
    capture_parse_result(() => {
      optional.parse_group_of_type("primitive", PrimitiveArg, true)
    }) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "A primitive argument cannot be optional")
    _ => fail("expected optional primitive error")
  }
}

///|
test "parse_arguments applies optional arg types before mandatory arg types" {
  let parser = Parser::make("[red]{x}", Settings::default())
  let spec = FunctionSpec::make(["\\typed"], 1, num_optional_args=1, arg_types=[
    ColorArg,
    TextArg,
  ])
  let (args, opt_args) = parser.parse_arguments("\\typed", spec)
  assert_true(args is [OrdGroup(mode=Text, body=[TextOrd(text="x", ..)], ..)])
  assert_true(opt_args is [Some(ColorToken(color="red", ..))])

  let primitive = Parser::make("\\relax", Settings::default())
  let primitive_spec = FunctionSpec::make(["\\primitive"], 1, primitive=true)
  let (primitive_args, _) = primitive.parse_arguments(
    "\\primitive", primitive_spec,
  )
  assert_true(primitive_args is [Internal(mode=Math)])
}

///|
test "parse_arguments supports the sqrt primitive fallback policy" {
  let missing_optional = Parser::make("x", Settings::default())
  let spec = FunctionSpec::make(
    ["\\sqrt-like"],
    1,
    num_optional_args=1,
    primitive_after_missing_optional=0,
  )
  let (primitive_args, primitive_opt_args) = missing_optional.parse_arguments(
    "\\sqrt-like", spec,
  )
  assert_true(primitive_args is [MathOrd(text="x", ..)])
  assert_eq(primitive_opt_args, [None])

  let present_optional = Parser::make("[2]{x}", Settings::default())
  let (ordinary_args, ordinary_opt_args) = present_optional.parse_arguments(
    "\\sqrt-like", spec,
  )
  assert_true(ordinary_args is [OrdGroup(body=[MathOrd(text="x", ..)], ..)])
  assert_true(
    ordinary_opt_args is [Some(OrdGroup(body=[TextOrd(text="2", ..)], ..))],
  )
}
