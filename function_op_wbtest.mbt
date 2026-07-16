///|
test "big operators and Unicode aliases produce canonical limited symbols" {
  assert_true(
    parse("\\sum∏\\smallint")
    is [
      Op(limits=true, content=SymbolOperator("\\sum"), ..),
      Op(limits=true, content=SymbolOperator("\\prod"), ..),
      Op(limits=true, content=SymbolOperator("\\smallint"), ..),
    ],
  )
}

///|
test "integral operators normalize Unicode aliases and allow script arguments" {
  assert_true(
    parse("∫\\oiiint")
    is [
      Op(limits=false, content=SymbolOperator("\\int"), ..),
      Op(limits=false, content=SymbolOperator("\\oiiint"), ..),
    ],
  )
  assert_true(
    parse("x^\\int")
    is [SupSub(sup=Some(Op(content=SymbolOperator("\\int"), ..)), ..)],
  )
}

///|
test "named operators preserve their independent limit defaults" {
  assert_true(
    parse("\\sin\\lim")
    is [
      Op(limits=false, content=NamedOperator("\\sin"), ..),
      Op(limits=true, content=NamedOperator("\\lim"), ..),
    ],
  )
}

///|
test "mathop is primitive and stores its flattened body" {
  assert_true(
    parse("\\mathop{xy}")
    is [
      Op(
        limits=false,
        content=BodyOperator([MathOrd(text="x", ..), MathOrd(text="y", ..)]),
        ..
      ),
    ],
  )
}

///|
test "limit controls rebuild the preceding operator before scripts" {
  let limits_ast = parse("\\int\\limits_{a}^b")
  guard limits_ast
    is [
      SupSub(
        base=Some(Op(limits=true, always_handle_sup_sub=true, ..)),
        sup=Some(MathOrd(text="b", ..)),
        sub=Some(OrdGroup(body=[MathOrd(text="a", ..)], ..)),
        ..
      ),
    ] else {
    fail("\{to_repr(limits_ast)}")
  }
  assert_true(
    parse("\\sum\\nolimits_a")
    is [SupSub(base=Some(Op(limits=false, always_handle_sup_sub=true, ..)), ..)],
  )
}

///|
test "limit controls reject non-operators" {
  match capture_parse_result(() => parse("x\\limits")) {
    Err(
      InvalidArgument(message="Limit controls must follow a math operator", ..)
    ) => ()
    _ => fail("expected invalid limit control")
  }
}

///|
test "operator registry specs match KaTeX permissions" {
  let big = require_function(builtin_function_registry, "\\sum")
  assert_eq(big.names.length(), 26)
  assert_eq(big.num_args, 0)
  let mathop = require_function(builtin_function_registry, "\\mathop")
  assert_true(mathop.primitive)
  assert_eq(mathop.num_args, 1)
  let integral = require_function(builtin_function_registry, "\\int")
  assert_true(integral.allowed_in_argument)
  assert_eq(integral.names.length(), 12)
}
