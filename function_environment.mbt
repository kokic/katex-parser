///|
fn environment_name(arg : ParseNode) -> String raise ParseFailure {
  guard arg is OrdGroup(body~, ..) else {
    raise InvalidArgument(message="Invalid environment name", loc=None)
  }
  let builder = StringBuilder()
  for node in body {
    guard node is TextOrd(text~, ..) else {
      raise InvalidArgument(message="Invalid environment name", loc=None)
    }
    builder.write_string(text)
  }
  builder.to_string()
}

///|
fn begin_end_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\begin", "\\end"],
    1,
    arg_types=[TextArg],
    handler=environment_handler,
  )
}

///|
fn environment_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let name = environment_name(require_function_arg(args, 0, context.func_name))
  if context.func_name == "\\begin" {
    (context.parse_environment)(name)
  } else {
    EnvironmentEnd(mode=context.mode, name~)
  }
}

///|
fn hline_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\hline", "\\hdashline"],
    0,
    allowed_in_text=true,
    handler=hline_handler,
  )
}

///|
fn hline_handler(
  context : FunctionContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  raise InvalidArgument(
    message=context.func_name + " valid only within array environment",
    loc=None,
  )
}
