///|
fn x_arrow_spec() -> FunctionSpec {
  FunctionSpec::make(
    [
      "\\xleftarrow", "\\xrightarrow", "\\xLeftarrow", "\\xRightarrow", "\\xleftrightarrow",
      "\\xLeftrightarrow", "\\xhookleftarrow", "\\xhookrightarrow", "\\xmapsto",
      "\\xrightharpoondown", "\\xrightharpoonup", "\\xleftharpoondown", "\\xleftharpoonup",
      "\\xrightleftharpoons", "\\xleftrightharpoons", "\\xlongequal", "\\xtwoheadrightarrow",
      "\\xtwoheadleftarrow", "\\xtofrom", "\\xrightleftarrows", "\\xrightequilibrium",
      "\\xleftequilibrium", "\\\\cdrightarrow", "\\\\cdleftarrow", "\\\\cdlongequal",
    ],
    1,
    num_optional_args=1,
    handler=x_arrow_handler,
  )
}

///|
fn x_arrow_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  XArrow(
    mode=context.mode,
    label=context.func_name,
    body=require_function_arg(args, 0, context.func_name),
    below=opt_args.get(0).unwrap_or(None),
  )
}
