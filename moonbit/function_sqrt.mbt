///|
fn sqrt_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\sqrt"],
    1,
    num_optional_args=1,
    primitive_after_missing_optional=0,
    handler=sqrt_handler,
  )
}

///|
fn sqrt_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  guard args.get(0) is Some(body) else {
    raise InternalInvariant(message="Missing body argument for \\sqrt")
  }
  guard opt_args.get(0) is Some(index) else {
    raise InternalInvariant(message="Missing optional argument slot for \\sqrt")
  }
  Sqrt(mode=context.mode, body~, index~)
}
