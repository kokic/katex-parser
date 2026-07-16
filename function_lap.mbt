///|
fn lap_alignment(func_name : String) -> LapAlignment raise ParseFailure {
  match func_name {
    "\\mathllap" => LLap
    "\\mathrlap" => RLap
    "\\mathclap" => CLap
    _ => raise InternalInvariant(message="Unknown lap command: " + func_name)
  }
}

///|
fn lap_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\mathllap", "\\mathrlap", "\\mathclap"],
    1,
    allowed_in_text=true,
    handler=lap_handler,
  )
}

///|
fn lap_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Lap(
    mode=context.mode,
    alignment=lap_alignment(context.func_name),
    body=require_function_arg(args, 0, context.func_name),
  )
}
