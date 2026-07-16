///|
fn colorbox_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\colorbox"],
    2,
    arg_types=[ColorArg, HboxArg],
    allowed_in_text=true,
    handler=colorbox_handler,
  )
}

///|
fn colorbox_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Enclose(
    mode=context.mode,
    label=context.func_name,
    background_color=Some(require_color_argument(args, context.func_name)),
    border_color=None,
    body=require_function_arg(args, 1, context.func_name),
  )
}

///|
fn fcolorbox_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\fcolorbox"],
    3,
    arg_types=[ColorArg, ColorArg, HboxArg],
    allowed_in_text=true,
    handler=fcolorbox_handler,
  )
}

///|
fn fcolorbox_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Enclose(
    mode=context.mode,
    label=context.func_name,
    border_color=Some(require_color_argument_at(args, 0, context.func_name)),
    background_color=Some(require_color_argument_at(args, 1, context.func_name)),
    body=require_function_arg(args, 2, context.func_name),
  )
}

///|
fn fbox_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\fbox"],
    1,
    arg_types=[HboxArg],
    allowed_in_text=true,
    handler=enclose_handler,
  )
}

///|
fn cancel_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\cancel", "\\bcancel", "\\xcancel", "\\phase"],
    1,
    handler=enclose_handler,
  )
}

///|
fn sout_spec() -> FunctionSpec {
  FunctionSpec::make(["\\sout"], 1, allowed_in_text=true, handler=sout_handler)
}

///|
fn sout_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  if context.mode == Math {
    (context.report_nonstrict)(
      "mathVsSout", "LaTeX's \\sout works only in text mode",
    )
  }
  enclose_node(context, args, 0)
}

///|
fn angl_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\angl"],
    1,
    arg_types=[HboxArg],
    handler=enclose_handler,
  )
}

///|
fn enclose_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  enclose_node(context, args, 0)
}

///|
fn enclose_node(
  context : FunctionContext,
  args : Array[ParseNode],
  body_index : Int,
) -> ParseNode raise ParseFailure {
  Enclose(
    mode=context.mode,
    label=context.func_name,
    background_color=None,
    border_color=None,
    body=require_function_arg(args, body_index, context.func_name),
  )
}
