///|
fn require_color_argument(
  args : Array[ParseNode],
  func_name : String,
) -> String raise ParseFailure {
  require_color_argument_at(args, 0, func_name)
}

///|
fn require_color_argument_at(
  args : Array[ParseNode],
  index : Int,
  func_name : String,
) -> String raise ParseFailure {
  guard require_function_arg(args, index, func_name) is ColorToken(color~, ..) else {
    raise InternalInvariant(message="Expected color argument for " + func_name)
  }
  color
}

///|
fn textcolor_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\textcolor"],
    2,
    arg_types=[ColorArg, OriginalArg],
    allowed_in_text=true,
    handler=textcolor_handler,
  )
}

///|
fn textcolor_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Color(
    mode=context.mode,
    color=require_color_argument(args, context.func_name),
    body=ord_argument(require_function_arg(args, 1, context.func_name)),
  )
}

///|
fn color_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\color"],
    1,
    arg_types=[ColorArg],
    allowed_in_text=true,
    handler=color_handler,
  )
}

///|
fn color_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let color = require_color_argument(args, context.func_name)
  (context.set_macro)("\\current@color", Some(MacroDefinition::text(color)))
  Color(
    mode=context.mode,
    color~,
    body=(context.parse_expression)(true, context.break_on_token_text),
  )
}
