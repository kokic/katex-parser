///|
fn mathchoice_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\mathchoice"],
    4,
    primitive=true,
    handler=mathchoice_handler,
  )
}

///|
fn mathchoice_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  MathChoice(
    mode=context.mode,
    display=ord_argument(require_function_arg(args, 0, context.func_name)),
    text=ord_argument(require_function_arg(args, 1, context.func_name)),
    script=ord_argument(require_function_arg(args, 2, context.func_name)),
    scriptscript=ord_argument(require_function_arg(args, 3, context.func_name)),
  )
}
