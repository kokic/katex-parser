///|
test "sqrt parses primitive and braced bodies without an index" {
  assert_true(
    parse("\\sqrt x")
    is [Sqrt(mode=Math, body=MathOrd(mode=Math, text="x", ..), index=None)],
  )
  assert_true(
    parse("\\sqrt{x+1}")
    is [
      Sqrt(
        mode=Math,
        body=OrdGroup(
          mode=Math,
          body=[
            MathOrd(text="x", ..),
            Atom(family=Mbin, text="+", ..),
            TextOrd(text="1", ..),
          ],
          ..
        ),
        index=None
      ),
    ],
  )
}

///|
test "sqrt parses present and empty optional indexes" {
  assert_true(
    parse("\\sqrt[3]{x}")
    is [
      Sqrt(
        body=OrdGroup(body=[MathOrd(text="x", ..)], ..),
        index=Some(OrdGroup(body=[TextOrd(text="3", ..)], ..)),
        ..
      ),
    ],
  )
  assert_true(
    parse("\\sqrt[]x")
    is [
      Sqrt(
        body=OrdGroup(body=[MathOrd(text="x", ..)], ..),
        index=Some(OrdGroup(body=[], ..)),
        ..
      ),
    ],
  )
}

///|
test "sqrt reports missing body and text-mode use" {
  match capture_parse_result(() => parse("\\sqrt")) {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "Expected group as argument to '\\sqrt'")
    _ => fail("expected missing sqrt body")
  }

  let text_parser = Parser::make("\\sqrt{x}", Settings::default())
  text_parser.switch_mode(Text)
  match capture_parse_result(() => text_parser.parse()) {
    Err(FunctionNotAllowed(func_name="\\sqrt", context="text mode", ..)) => ()
    _ => fail("expected text-mode sqrt error")
  }
}

///|
test "sqrt registry spec uses the optional primitive fallback" {
  let spec = require_function(builtin_function_registry, "\\sqrt")
  assert_eq(spec.num_args, 1)
  assert_eq(spec.num_optional_args, 1)
  assert_eq(spec.primitive_after_missing_optional, Some(0))
  assert_true(spec.handler is Some(_))
  assert_true(default_command_status("\\sqrt") is ExternalExpandable)
}
