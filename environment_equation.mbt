///|
fn equation_environment_handler(
  context : EnvironmentContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  guard context.display_mode else {
    raise InvalidArgument(
      message="{" + context.env_name + "} can be used only in display mode.",
      loc=None,
    )
  }
  (context.parse_array)({
    columns: None,
    array_stretch: 1.0,
    hskip_before_and_after: false,
    cell_style: DisplayStyle,
    max_columns: Some(1),
    single_row: true,
    auto_tag: Some(context.env_name == "equation"),
    leqno: context.leqno,
  })
}
