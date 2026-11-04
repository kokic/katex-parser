///|
fn phantom_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\phantom"],
    1,
    allowed_in_text=true,
    handler=phantom_handler,
  )
}

///|
fn phantom_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Phantom(
    mode=context.mode,
    body=ord_argument(require_function_arg(args, 0, context.func_name)),
  )
}

///|
fn vphantom_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\vphantom"],
    1,
    allowed_in_text=true,
    handler=vphantom_handler,
  )
}

///|
fn vphantom_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  VPhantom(
    mode=context.mode,
    body=require_function_arg(args, 0, context.func_name),
  )
}
