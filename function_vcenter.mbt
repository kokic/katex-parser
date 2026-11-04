///|
fn vcenter_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\vcenter"],
    1,
    arg_types=[OriginalArg],
    allowed_in_math=true,
    allowed_in_text=false,
    handler=vcenter_handler,
  )
}

///|
fn vcenter_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  VCenter(
    mode=context.mode,
    body=require_function_arg(args, 0, context.func_name),
  )
}
