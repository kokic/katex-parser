///|
fn style_level(func_name : String) -> StyleLevel raise ParseFailure {
  match func_name {
    "\\displaystyle" => DisplayStyle
    "\\textstyle" => TextStyle
    "\\scriptstyle" => ScriptStyle
    "\\scriptscriptstyle" => ScriptScriptStyle
    _ =>
      raise InternalInvariant(message="Unknown styling command: " + func_name)
  }
}

///|
fn styling_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\displaystyle", "\\textstyle", "\\scriptstyle", "\\scriptscriptstyle"],
    0,
    allowed_in_text=true,
    primitive=true,
    handler=styling_handler,
  )
}

///|
fn styling_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Styling(
    mode=context.mode,
    body=(context.parse_expression)(true, context.break_on_token_text),
    style=style_level(context.func_name),
    reset_font=false,
  )
}
