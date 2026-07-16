///|
let sizing_commands : Array[String] = [
  "\\tiny", "\\sixptsize", "\\scriptsize", "\\footnotesize", "\\small", "\\normalsize",
  "\\large", "\\Large", "\\LARGE", "\\huge", "\\Huge",
]

///|
fn sizing_index(func_name : String) -> Int raise ParseFailure {
  for index, command in sizing_commands {
    guard command == func_name else { continue }
    return index + 1
  }
  raise InternalInvariant(message="Unknown sizing command: " + func_name)
}

///|
fn sizing_spec() -> FunctionSpec {
  FunctionSpec::make(
    sizing_commands,
    0,
    allowed_in_text=true,
    handler=sizing_handler,
  )
}

///|
fn sizing_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Sizing(
    mode=context.mode,
    size=sizing_index(context.func_name),
    body=(context.parse_expression)(false, context.break_on_token_text),
  )
}
