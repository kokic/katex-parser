///|
fn raisebox_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\raisebox"],
    2,
    arg_types=[SizeArg, HboxArg],
    allowed_in_text=true,
    handler=raisebox_handler,
  )
}

///|
fn raisebox_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let amount = require_size_argument(
    require_function_arg(args, 0, context.func_name),
    context.func_name,
  )
  RaiseBox(
    mode=context.mode,
    dy=amount,
    body=require_function_arg(args, 1, context.func_name),
  )
}
