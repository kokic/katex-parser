///|
fn pmb_spec() -> FunctionSpec {
  FunctionSpec::make(["\\pmb"], 1, allowed_in_text=true, handler=pmb_handler)
}

///|
fn pmb_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let arg = require_function_arg(args, 0, context.func_name)
  Pmb(mode=context.mode, mclass=binrel_class(arg), body=ord_argument(arg))
}
