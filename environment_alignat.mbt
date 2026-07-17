///|
fn environment_argument_text(arg : ParseNode) -> String raise ParseFailure {
  let nodes = match arg {
    OrdGroup(body~, ..) => body
    _ => [arg]
  }
  let mut text = ""
  for node in nodes {
    let part = match node {
      MathOrd(text~, ..) | TextOrd(text~, ..) | Atom(text~, ..) => text
      _ =>
        raise InvalidArgument(
          message="Invalid alignment column count",
          loc=None,
        )
    }
    text = text + part
  }
  text
}

///|
fn alignat_pair_count(arg : ParseNode) -> Int raise ParseFailure {
  let text = environment_argument_text(arg)
  guard parse_argument_count(text) is Some(count) && count >= 0 else {
    raise InvalidArgument(message="Invalid alignment column count", loc=None)
  }
  count
}

///|
fn alignat_environment_handler(
  context : EnvironmentContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  if context.env_name != "alignedat" && !context.display_mode {
    raise InvalidArgument(
      message="{" + context.env_name + "} can be used only in display mode.",
      loc=None,
    )
  }
  let pairs = alignat_pair_count(
    require_function_arg(args, 0, "\\begin{" + context.env_name + "}"),
  )
  let auto_tag = match context.env_name {
    "alignat" => Some(true)
    "alignat*" => Some(false)
    _ => None
  }
  let array = (context.parse_array)({
    columns: None,
    array_stretch: 1.0,
    hskip_before_and_after: false,
    cell_style: DisplayStyle,
    max_columns: Some(pairs * 2),
    single_row: false,
    auto_tag,
    leqno: context.leqno,
    add_jot: true,
    column_separation_type: Some(AlignAtSeparation),
  })
  let array = insert_alignment_empty_groups(array)
  replace_alignment_columns(
    array,
    alignment_columns(matrix_column_count(array_body(array)), false),
  )
}
