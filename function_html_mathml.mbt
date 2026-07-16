///|
fn html_mathml_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\html@mathml"],
    2,
    allowed_in_argument=true,
    allowed_in_text=true,
    handler=html_mathml_handler,
  )
}

///|
fn html_mathml_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  HtmlMathML(
    mode=context.mode,
    html=ord_argument(require_function_arg(args, 0, context.func_name)),
    mathml=ord_argument(require_function_arg(args, 1, context.func_name)),
  )
}
