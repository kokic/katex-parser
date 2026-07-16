///|
fn cases_columns() -> Array[ArrayColumn] {
  [
    AlignColumn(alignment="l", pre_gap=0.0, post_gap=1.0),
    AlignColumn(alignment="l", pre_gap=0.0, post_gap=0.0),
  ]
}

///|
fn cases_environment_handler(
  context : EnvironmentContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let array = (context.parse_array)({
    columns: Some(cases_columns()),
    array_stretch: 1.2,
    hskip_before_and_after: false,
    cell_style: if context.env_name == "dcases" || context.env_name == "drcases" {
      DisplayStyle
    } else {
      TextStyle
    },
    max_columns: None,
    single_row: false,
    auto_tag: None,
    leqno: false,
  })
  let right_brace = context.env_name == "rcases" ||
    context.env_name == "drcases"
  LeftRight(
    mode=context.mode,
    body=[array],
    left=if right_brace { "." } else { "\\{" },
    right=if right_brace { "\\}" } else { "." },
    right_color=None,
  )
}
