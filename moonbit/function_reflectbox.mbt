///|
fn reflectbox_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\reflectbox"],
    1,
    arg_types=[HboxArg],
    allowed_in_text=true,
    handler=reflectbox_handler,
  )
}

///|
fn mathreflectbox_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\mathreflectbox"],
    1,
    arg_types=[MathArg],
    handler=reflectbox_handler,
  )
}

///|
fn reflectbox_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  ReflectBox(
    mode=context.mode,
    body=require_function_arg(args, 0, context.func_name),
  )
}
