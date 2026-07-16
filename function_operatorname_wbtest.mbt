///|
test "operatorname macro routes ordinary and star forms" {
  assert_true(
    parse("\\operatorname{foo}\\operatorname*{bar}")
    is [
      OperatorName(
        body=[
          MathOrd(text="f", ..),
          MathOrd(text="o", ..),
          MathOrd(text="o", ..),
        ],
        always_handle_sup_sub=false,
        limits=false,
        ..
      ),
      OperatorName(
        body=[
          MathOrd(text="b", ..),
          MathOrd(text="a", ..),
          MathOrd(text="r", ..),
        ],
        always_handle_sup_sub=true,
        limits=false,
        ..
      ),
    ],
  )
}

///|
test "operatorname star form accepts limit controls" {
  assert_true(
    parse("\\operatorname*{lim}\\limits_a")
    is [
      SupSub(
        base=Some(OperatorName(always_handle_sup_sub=true, limits=true, ..)),
        sub=Some(MathOrd(text="a", ..)),
        ..
      ),
    ],
  )
}

///|
test "operatorname registry spec matches KaTeX internal commands" {
  let spec = require_function(builtin_function_registry, "\\operatorname@")
  assert_eq(spec.names.length(), 2)
  assert_eq(spec.num_args, 1)
  assert_false(spec.allowed_in_argument)
  assert_false(spec.allowed_in_text)
}
