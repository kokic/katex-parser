///|
fn cd_internal_spec() -> FunctionSpec {
  FunctionSpec::make(["\\\\cdleft", "\\\\cdright"], 1, handler=cd_label_handler)
}

///|
fn cd_label_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  CdLabel(
    mode=context.mode,
    side=if context.func_name == "\\\\cdleft" { "left" } else { "right" },
    label=require_function_arg(args, 0, context.func_name),
  )
}

///|
fn cd_parent_spec() -> FunctionSpec {
  FunctionSpec::make(["\\\\cdparent"], 1, handler=cd_parent_handler)
}

///|
fn cd_parent_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  CdParent(
    mode=context.mode,
    fragment=require_function_arg(args, 0, context.func_name),
  )
}
