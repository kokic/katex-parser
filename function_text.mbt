///|
fn text_spec() -> FunctionSpec {
  FunctionSpec::make(
    [
      "\\text", "\\textrm", "\\textsf", "\\texttt", "\\textnormal", "\\textbf", "\\textmd",
      "\\textit", "\\textup", "\\emph",
    ],
    1,
    arg_types=[TextArg],
    allowed_in_argument=true,
    allowed_in_text=true,
    handler=text_handler,
  )
}

///|
fn text_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Text(
    mode=context.mode,
    body=ord_argument(require_function_arg(args, 0, context.func_name)),
    font=context.func_name,
  )
}
