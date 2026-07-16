///|
fn matrix_column_count(body : Array[Array[ParseNode]]) -> Int {
  let mut count = 0
  for row in body {
    if row.length() > count {
      count = row.length()
    }
  }
  count
}

///|
fn matrix_columns(count : Int, alignment : String) -> Array[ArrayColumn] {
  let columns : Array[ArrayColumn] = []
  for _ in 0..<count {
    columns.push(AlignColumn(alignment~, pre_gap=0.0, post_gap=0.0))
  }
  columns
}

///|
fn array_with_columns(
  node : ParseNode,
  columns : Array[ArrayColumn],
) -> ParseNode raise ParseFailure {
  match node {
    Array(
      mode~,
      body~,
      add_jot~,
      array_stretch~,
      row_gaps~,
      hskip_before_and_after~,
      hlines_before_row~,
      column_separation_type~,
      tags~,
      auto_tags~,
      leqno~,
      ..
    ) =>
      Array(
        mode~,
        body~,
        add_jot~,
        array_stretch~,
        columns=Some(columns),
        row_gaps~,
        hskip_before_and_after~,
        hlines_before_row~,
        column_separation_type~,
        tags~,
        auto_tags~,
        leqno~,
      )
    _ => raise InternalInvariant(message="Expected matrix array")
  }
}

///|
fn matrix_delimiters(name : String) -> (String, String)? {
  match name {
    "matrix" => None
    "pmatrix" => Some(("(", ")"))
    "bmatrix" => Some(("[", "]"))
    "Bmatrix" => Some(("\\{", "\\}"))
    "vmatrix" => Some(("|", "|"))
    "Vmatrix" => Some(("\\Vert", "\\Vert"))
    _ => None
  }
}

///|
fn matrix_environment_handler(
  context : EnvironmentContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let starred = context.env_name.length() > 0 &&
    context.env_name[context.env_name.length() - 1] == '*'
  let base_name = if starred {
    context.env_name.unsafe_substring(
      start=0,
      end=context.env_name.length() - 1,
    )
  } else {
    context.env_name
  }
  let requested_alignment = if starred {
    (context.parse_matrix_alignment)()
  } else {
    None
  }
  let alignment = match requested_alignment {
    Some(value) => value
    None => "c"
  }
  let array = (context.parse_array)({
    columns: None,
    array_stretch: 1.0,
    hskip_before_and_after: false,
    cell_style: TextStyle,
    max_columns: None,
    single_row: false,
    auto_tag: None,
    leqno: false,
    add_jot: false,
    column_separation_type: None,
  })
  let array = match array {
    Array(body~, ..) =>
      array_with_columns(
        array,
        matrix_columns(matrix_column_count(body), alignment),
      )
    _ => raise InternalInvariant(message="Expected matrix array")
  }
  match matrix_delimiters(base_name) {
    None => array
    Some((left, right)) =>
      LeftRight(
        mode=context.mode,
        body=[array],
        left~,
        right~,
        right_color=None,
      )
  }
}

///|
fn smallmatrix_environment_handler(
  context : EnvironmentContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let array = (context.parse_array)({
    columns: None,
    array_stretch: 0.5,
    hskip_before_and_after: false,
    cell_style: ScriptStyle,
    max_columns: None,
    single_row: false,
    auto_tag: None,
    leqno: false,
    add_jot: false,
    column_separation_type: Some(SmallSeparation),
  })
  match array {
    Array(body~, ..) =>
      array_with_columns(array, matrix_columns(matrix_column_count(body), "c"))
    _ => raise InternalInvariant(message="Expected smallmatrix array")
  }
}
