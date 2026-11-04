///|
fn overline_spec() -> FunctionSpec {
  FunctionSpec::make(["\\overline"], 1, handler=overline_handler)
}

///|
fn overline_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Overline(
    mode=context.mode,
    body=require_function_arg(args, 0, context.func_name),
  )
}
