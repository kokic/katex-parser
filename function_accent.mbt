///|
fn accent_spec() -> FunctionSpec {
  FunctionSpec::make(
    [
      "\\acute", "\\grave", "\\ddot", "\\tilde", "\\bar", "\\breve", "\\check", "\\hat",
      "\\vec", "\\dot", "\\mathring", "\\widecheck", "\\widehat", "\\widetilde",
      "\\overrightarrow", "\\overleftarrow", "\\Overrightarrow", "\\overleftrightarrow",
      "\\overgroup", "\\overlinesegment", "\\overleftharpoon", "\\overrightharpoon",
    ],
    1,
    handler=accent_handler,
  )
}

///|
fn is_non_stretchy_accent(func_name : String) -> Bool {
  match func_name {
    "\\acute"
    | "\\grave"
    | "\\ddot"
    | "\\tilde"
    | "\\bar"
    | "\\breve"
    | "\\check"
    | "\\hat"
    | "\\vec"
    | "\\dot"
    | "\\mathring" => true
    _ => false
  }
}

///|
fn accent_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let is_stretchy = !is_non_stretchy_accent(context.func_name)
  Accent(
    mode=context.mode,
    loc=None,
    label=context.func_name,
    is_stretchy~,
    is_shifty=!is_stretchy ||
      context.func_name == "\\widehat" ||
      context.func_name == "\\widetilde" ||
      context.func_name == "\\widecheck",
    base=normalize_argument(require_function_arg(args, 0, context.func_name)),
  )
}

///|
fn text_accent_spec() -> FunctionSpec {
  FunctionSpec::make(
    [
      "\\'", "\\`", "\\^", "\\~", "\\=", "\\u", "\\.", "\\\"", "\\c", "\\r", "\\H",
      "\\v", "\\textcircled",
    ],
    1,
    arg_types=[PrimitiveArg],
    allowed_in_text=true,
    handler=text_accent_handler,
  )
}

///|
fn text_accent_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let mode = if context.mode == Math {
    (context.report_nonstrict)(
      "mathVsTextAccents",
      "LaTeX's accent " + context.func_name + " works only in text mode",
    )
    Mode::Text
  } else {
    context.mode
  }
  Accent(
    mode~,
    loc=None,
    label=context.func_name,
    is_stretchy=false,
    is_shifty=true,
    base=require_function_arg(args, 0, context.func_name),
  )
}
