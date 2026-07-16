///|
fn math_mode_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\(", "$"],
    0,
    allowed_in_text=true,
    allowed_in_math=false,
    handler=math_mode_handler,
  )
}

///|
fn math_mode_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let close = if context.func_name == "\\(" { "\\)" } else { "$" }
  Styling(
    mode=context.mode,
    style=TextStyle,
    reset_font=true,
    body=(context.parse_math_mode)(close),
  )
}

///|
fn math_closing_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\)", "\\]"],
    0,
    allowed_in_text=true,
    allowed_in_math=false,
    handler=math_closing_handler,
  )
}

///|
fn math_closing_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let loc = match context.token {
    Some(token) => token.loc
    None => None
  }
  raise InvalidArgument(message="Mismatched " + context.func_name, loc~)
}
