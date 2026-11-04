///|
fn hbox_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\hbox"],
    1,
    arg_types=[TextArg],
    allowed_in_text=true,
    primitive=true,
    handler=hbox_handler,
  )
}

///|
fn hbox_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  HBox(
    mode=context.mode,
    body=ord_argument(require_function_arg(args, 0, context.func_name)),
  )
}
