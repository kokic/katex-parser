///|
fn require_size_argument(
  arg : ParseNode,
  func_name : String,
) -> Measurement raise ParseFailure {
  guard arg is Size(value~, ..) else {
    raise InternalInvariant(message="Expected size argument for " + func_name)
  }
  value
}

///|
fn rule_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\rule"],
    2,
    num_optional_args=1,
    arg_types=[SizeArg, SizeArg, SizeArg],
    allowed_in_text=true,
    handler=rule_handler,
  )
}

///|
fn rule_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let shift = match opt_args.get(0).unwrap_or(None) {
    None => None
    Some(arg) => Some(require_size_argument(arg, context.func_name))
  }
  Rule(
    mode=context.mode,
    shift~,
    width=require_size_argument(
      require_function_arg(args, 0, context.func_name),
      context.func_name,
    ),
    height=require_size_argument(
      require_function_arg(args, 1, context.func_name),
      context.func_name,
    ),
  )
}
