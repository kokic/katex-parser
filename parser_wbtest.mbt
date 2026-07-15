///|
test "parse simple math symbols" {
  debug_inspect(
    parse("x+1"),
    content=(
      #|[
      #|  MathOrd(
      #|    mode=Math,
      #|    loc=Some({ input: "x+1", start: 0, end: 1 }),
      #|    text="x",
      #|  ),
      #|  Atom(
      #|    mode=Math,
      #|    loc=Some({ input: "x+1", start: 1, end: 2 }),
      #|    family=Mbin,
      #|    text="+",
      #|  ),
      #|  TextOrd(
      #|    mode=Math,
      #|    loc=Some({ input: "x+1", start: 2, end: 3 }),
      #|    text="1",
      #|  ),
      #|]
    ),
  )
}

///|
test "parse superscript" {
  debug_inspect(
    parse("x^2"),
    content=(
      #|[
      #|  SupSub(
      #|    mode=Math,
      #|    base=Some(
      #|      MathOrd(
      #|        mode=Math,
      #|        loc=Some({ input: "x^2", start: 0, end: 1 }),
      #|        text="x",
      #|      ),
      #|    ),
      #|    sup=Some(
      #|      TextOrd(
      #|        mode=Math,
      #|        loc=Some({ input: "x^2", start: 2, end: 3 }),
      #|        text="2",
      #|      ),
      #|    ),
      #|    sub=None,
      #|  ),
      #|]
    ),
  )
}

///|
test "parse braced group" {
  debug_inspect(
    parse("{xy}"),
    content=(
      #|[
      #|  OrdGroup(
      #|    mode=Math,
      #|    loc=Some({ input: "{xy}", start: 0, end: 4 }),
      #|    body=[
      #|      MathOrd(
      #|        mode=Math,
      #|        loc=Some({ input: "{xy}", start: 1, end: 2 }),
      #|        text="x",
      #|      ),
      #|      MathOrd(
      #|        mode=Math,
      #|        loc=Some({ input: "{xy}", start: 2, end: 3 }),
      #|        text="y",
      #|      ),
      #|    ],
      #|    semisimple=false,
      #|  ),
      #|]
    ),
  )
}

///|
test "Parser::parse_arguments parses original groups through gullet" {
  let parser = Parser::make("{xy}", Settings::default())
  let spec : FunctionSpec = {
    num_args: 1,
    num_optional_args: 0,
    arg_types: [OriginalArg],
    allowed_in_argument: false,
    allowed_in_text: false,
    allowed_in_math: true,
    handler: (_parser, _args, _opt_args) => None,
  }
  debug_inspect(
    parser.parse_arguments("\\test", spec),
    content=(
      #|(
      #|  [
      #|    OrdGroup(
      #|      mode=Math,
      #|      loc=Some({ input: "{xy}", start: 0, end: 4 }),
      #|      body=[
      #|        MathOrd(
      #|          mode=Math,
      #|          loc=Some({ input: "{xy}", start: 1, end: 2 }),
      #|          text="x",
      #|        ),
      #|        MathOrd(
      #|          mode=Math,
      #|          loc=Some({ input: "{xy}", start: 2, end: 3 }),
      #|          text="y",
      #|        ),
      #|      ],
      #|      semisimple=false,
      #|    ),
      #|  ],
      #|  [],
      #|)
    ),
  )
}

///|
test "Parser::parse unwinds every namespace after an error" {
  let parser = Parser::make("\\missing", Settings::default())
  match capture_parse_result(() => parser.parse()) {
    Err(UndefinedControlSequence(name="\\missing", ..)) => ()
    _ => fail("expected undefined control sequence")
  }
  assert_true(parser.gullet.macros.undo_stack.is_empty())
  assert_true(parser.gullet.dynamic_macros.undo_stack.is_empty())
}

///|
test "Parser::subparse restores lookahead after an error" {
  let parser = Parser::make("", Settings::default())
  let saved = Token::make("saved")
  parser.next_token = Some(saved)
  match
    capture_parse_result(() => parser.subparse([Token::make("\\missing")])) {
    Err(UndefinedControlSequence(name="\\missing", ..)) => ()
    _ => fail("expected undefined control sequence")
  }
  assert_eq(parser.next_token, Some(saved))
}

///|
test "Parser::parse_argument_group closes its namespace after an error" {
  let parser = Parser::make("{\\missing}", Settings::default())
  match capture_parse_result(() => parser.parse_argument_group(false)) {
    Err(UndefinedControlSequence(name="\\missing", ..)) => ()
    _ => fail("expected undefined control sequence")
  }
  assert_true(parser.gullet.macros.undo_stack.is_empty())
  assert_true(parser.gullet.dynamic_macros.undo_stack.is_empty())
}
