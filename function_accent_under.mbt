///|
fn accent_under_spec() -> FunctionSpec {
  FunctionSpec::make(
    [
      "\\underleftarrow", "\\underrightarrow", "\\underleftrightarrow", "\\undergroup",
      "\\underlinesegment", "\\utilde",
    ],
    1,
    handler=accent_under_handler,
  )
}

///|
fn accent_under_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  AccentUnder(
    mode=context.mode,
    label=context.func_name,
    base=require_function_arg(args, 0, context.func_name),
  )
}
