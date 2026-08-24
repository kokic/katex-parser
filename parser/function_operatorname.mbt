///|
fn operatorname_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\operatorname@", "\\operatornamewithlimits"],
    1,
    handler=operatorname_handler,
  )
}

///|
fn operatorname_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  OperatorName(
    mode=context.mode,
    body=ord_argument(require_function_arg(args, 0, context.func_name)),
    always_handle_sup_sub=context.func_name == "\\operatornamewithlimits",
    limits=false,
    parent_is_sup_sub=false,
  )
}
