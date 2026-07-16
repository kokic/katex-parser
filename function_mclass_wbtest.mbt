///|
test "math class commands map all primitive classes and flatten bodies" {
  let cases : Array[(String, AtomFamily)] = [
    ("\\mathord", Mord),
    ("\\mathbin", Mbin),
    ("\\mathrel", Mrel),
    ("\\mathopen", Mopen),
    ("\\mathclose", Mclose),
    ("\\mathpunct", Mpunct),
    ("\\mathinner", Minner),
  ]
  for item in cases {
    let (command, expected) = item
    guard parse(command + "{x}")
      is [
        MClass(
          mode=Math,
          mclass~,
          body=[MathOrd(text="x", ..)],
          is_character_box=true
        ),
      ] else {
      fail("unexpected math class AST")
    }
    assert_eq(mclass, expected)
  }
  assert_true(
    parse("\\mathord{xy}")
    is [
      MClass(
        mclass=Mord,
        body=[MathOrd(..), MathOrd(..)],
        is_character_box=false,
        ..
      ),
    ],
  )
}

///|
test "binrel derives class from its first argument and renders its second" {
  assert_true(
    parse("\\@binrel{+}{x}\\@binrel{=}{y}\\@binrel{z}{q}")
    is [
      MClass(
        mclass=Mbin,
        body=[MathOrd(text="x", ..)],
        is_character_box=true,
        ..
      ),
      MClass(
        mclass=Mrel,
        body=[MathOrd(text="y", ..)],
        is_character_box=true,
        ..
      ),
      MClass(
        mclass=Mord,
        body=[MathOrd(text="q", ..)],
        is_character_box=true,
        ..
      ),
    ],
  )
}

///|
test "stackrel builds a relation with an over-script body operator" {
  assert_true(
    parse("\\stackrel{a}{=}")
    is [
      MClass(
        mclass=Mrel,
        body=[
          SupSub(
            base=Some(
              Op(
                limits=true,
                always_handle_sup_sub=true,
                parent_is_sup_sub=false,
                suppress_base_shift=false,
                content=BodyOperator([Atom(family=Mrel, text="=", ..)]),
                ..
              )
            ),
            sup=Some(OrdGroup(body=[MathOrd(text="a", ..)], ..)),
            sub=None,
            ..
          ),
        ],
        is_character_box=false,
        ..
      ),
    ],
  )
}

///|
test "overset and underset inherit the base binrel class" {
  assert_true(
    parse("\\overset{a}{+}\\underset{b}{=}")
    is [
      MClass(
        mclass=Mbin,
        body=[
          SupSub(
            base=Some(Op(suppress_base_shift=true, ..)),
            sup=Some(OrdGroup(body=[MathOrd(text="a", ..)], ..)),
            sub=None,
            ..
          ),
        ],
        ..
      ),
      MClass(
        mclass=Mrel,
        body=[
          SupSub(
            base=Some(Op(suppress_base_shift=true, ..)),
            sup=None,
            sub=Some(OrdGroup(body=[MathOrd(text="b", ..)], ..)),
            ..
          ),
        ],
        ..
      ),
    ],
  )
}

///|
test "mclass registry specs match KaTeX primitive and argument metadata" {
  let mclass = require_function(builtin_function_registry, "\\mathord")
  assert_eq(mclass.names.length(), 7)
  assert_eq(mclass.num_args, 1)
  assert_true(mclass.primitive)
  assert_false(mclass.allowed_in_argument)
  let binrel = require_function(builtin_function_registry, "\\@binrel")
  assert_eq(binrel.num_args, 2)
  assert_false(binrel.primitive)
  let stackrel = require_function(builtin_function_registry, "\\stackrel")
  assert_eq(stackrel.names.length(), 3)
  assert_eq(stackrel.num_args, 2)
  assert_false(stackrel.primitive)
}
