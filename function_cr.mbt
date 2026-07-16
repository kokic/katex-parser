///|
fn cr_spec() -> FunctionSpec {
  FunctionSpec::make(["\\\\"], 0, allowed_in_text=true, handler=cr_handler)
}

///|
fn cr_handler(
  context : FunctionContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let new_line = !context.display_mode ||
    !(context.use_strict_behavior)(
      "newLineInDisplayMode", "In LaTeX, \\\\ or \\newline does nothing in display mode",
    )
  Cr(mode=context.mode, new_line~, size=(context.parse_optional_size)())
}
