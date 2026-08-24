///|
fn subarray_columns(arg : ParseNode) -> Array[ArrayColumn] raise ParseFailure {
  let columns = array_columns(arg, "subarray")
  guard columns.length() <= 1 else {
    raise InvalidArgument(
      message="{subarray} can contain only one column",
      loc=None,
    )
  }
  match columns {
    [] => columns
    [AlignColumn(alignment="l" | "c", ..)] => columns
    _ =>
      raise InvalidArgument(
        message="Unknown column alignment in subarray",
        loc=None,
      )
  }
}

///|
fn subarray_environment_handler(
  context : EnvironmentContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  (context.parse_array)({
    columns: Some(
      subarray_columns(require_function_arg(args, 0, "\\begin{subarray}")),
    ),
    array_stretch: 0.5,
    hskip_before_and_after: false,
    cell_style: ScriptStyle,
    max_columns: Some(1),
    single_row: false,
    auto_tag: None,
    leqno: false,
    add_jot: false,
    column_separation_type: Some(SmallSeparation),
  })
}
