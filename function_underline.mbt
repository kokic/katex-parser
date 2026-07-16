///|
fn underline_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\underline"],
    1,
    allowed_in_text=true,
    handler=underline_handler,
  )
}

///|
fn underline_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Underline(
    mode=context.mode,
    body=require_function_arg(args, 0, context.func_name),
  )
}
