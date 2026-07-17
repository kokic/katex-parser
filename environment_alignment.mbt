///|
fn array_body(node : ParseNode) -> Array[Array[ParseNode]] raise ParseFailure {
  match node {
    Array(body~, ..) => body
    _ => raise InternalInvariant(message="Expected alignment array")
  }
}

///|
fn alignment_columns(count : Int, aligned : Bool) -> Array[ArrayColumn] {
  Array::makei(count, index => {
    let alignment = if index % 2 == 0 { "r" } else { "l" }
    let pre_gap = if index % 2 == 0 && index > 0 && aligned { 1.0 } else { 0.0 }
    AlignColumn(alignment~, pre_gap~, post_gap=0.0)
  })
}

///|
fn replace_alignment_columns(
  node : ParseNode,
  columns : Array[ArrayColumn],
) -> ParseNode raise ParseFailure {
  array_with_columns(node, columns)
}

///|
fn alignment_rhs_cell(cell : ParseNode) -> ParseNode raise ParseFailure {
  match cell {
    Styling(
      mode~,
      style~,
      reset_font~,
      body=[OrdGroup(mode=inner_mode, loc~, body~, semisimple~)]
    ) =>
      Styling(mode~, style~, reset_font~, body=[
        OrdGroup(
          mode=inner_mode,
          loc~,
          body=[
            OrdGroup(mode=inner_mode, loc=None, body=[], semisimple=false),
            ..body,
          ],
          semisimple~,
        ),
      ])
    _ => raise InternalInvariant(message="Expected alignment cell")
  }
}

///|
fn insert_alignment_empty_groups(
  node : ParseNode,
) -> ParseNode raise ParseFailure {
  match node {
    Array(body~, ..) => {
      for row in body {
        for index = 1; index < row.length(); index = index + 2 {
          row[index] = alignment_rhs_cell(row[index])
        }
      }
      node
    }
    _ => raise InternalInvariant(message="Expected alignment array")
  }
}

///|
fn alignment_display_mode(
  context : EnvironmentContext,
) -> Unit raise ParseFailure {
  if context.env_name != "aligned" && !context.display_mode {
    raise InvalidArgument(
      message="{" + context.env_name + "} can be used only in display mode.",
      loc=None,
    )
  }
}

///|
fn aligned_environment_handler(
  context : EnvironmentContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  alignment_display_mode(context)
  let is_split = context.env_name == "split"
  let auto_tag = match context.env_name {
    "align" => Some(true)
    "align*" => Some(false)
    _ => None
  }
  let array = (context.parse_array)({
    columns: None,
    array_stretch: 1.0,
    hskip_before_and_after: false,
    cell_style: DisplayStyle,
    max_columns: if is_split {
      Some(2)
    } else {
      None
    },
    single_row: false,
    auto_tag,
    leqno: context.leqno,
    add_jot: true,
    column_separation_type: Some(AlignSeparation),
  })
  let array = insert_alignment_empty_groups(array)
  let columns = alignment_columns(
    matrix_column_count(array_body(array)),
    context.env_name == "aligned",
  )
  replace_alignment_columns(array, columns)
}

///|
fn gather_environment_handler(
  context : EnvironmentContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  if context.env_name != "gathered" && !context.display_mode {
    raise InvalidArgument(
      message="{" + context.env_name + "} can be used only in display mode.",
      loc=None,
    )
  }
  let auto_tag = match context.env_name {
    "gather" => Some(true)
    "gather*" => Some(false)
    _ => None
  }
  (context.parse_array)({
    columns: Some([AlignColumn(alignment="c", pre_gap=0.0, post_gap=0.0)]),
    array_stretch: 1.0,
    hskip_before_and_after: false,
    cell_style: DisplayStyle,
    max_columns: Some(1),
    single_row: false,
    auto_tag,
    leqno: context.leqno,
    add_jot: true,
    column_separation_type: Some(GatherSeparation),
  })
}
