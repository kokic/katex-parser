///|
fn horiz_brace_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\overbrace", "\\underbrace", "\\overbracket", "\\underbracket"],
    1,
    handler=horiz_brace_handler,
  )
}

///|
fn is_over_brace(func_name : String) -> Bool raise ParseFailure {
  match func_name {
    "\\overbrace" | "\\overbracket" => true
    "\\underbrace" | "\\underbracket" => false
    _ =>
      raise InternalInvariant(
        message="Unknown horizontal brace command: " + func_name,
      )
  }
}

///|
fn horiz_brace_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  HorizBrace(
    mode=context.mode,
    label=context.func_name,
    is_over=is_over_brace(context.func_name),
    base=require_function_arg(args, 0, context.func_name),
  )
}
