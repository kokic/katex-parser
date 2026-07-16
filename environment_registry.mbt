///|
priv struct ArrayEnvironmentOptions {
  columns : Array[ArrayColumn]?
  array_stretch : Double
  hskip_before_and_after : Bool
  cell_style : StyleLevel
  max_columns : Int?
  single_row : Bool
  auto_tag : Bool?
  leqno : Bool
  add_jot : Bool
  column_separation_type : ColumnSeparationType?
}

///|
priv struct EnvironmentContext {
  mode : Mode
  display_mode : Bool
  leqno : Bool
  env_name : String
  parse_array : (ArrayEnvironmentOptions) -> ParseNode raise ParseFailure
  parse_matrix_alignment : () -> String? raise ParseFailure
}

///|
type EnvironmentHandler = (
  EnvironmentContext,
  Array[ParseNode],
  Array[ParseNode?],
) -> ParseNode raise ParseFailure

///|
priv struct EnvironmentSpec {
  num_args : Int
  num_optional_args : Int
  arg_types : Array[ArgType]
  handler : EnvironmentHandler
}

///|
fn EnvironmentSpec::make(
  num_args : Int,
  num_optional_args? : Int = 0,
  arg_types? : Array[ArgType] = [],
  handler : EnvironmentHandler,
) -> EnvironmentSpec {
  { num_args, num_optional_args, arg_types, handler }
}

///|
fn array_columns(
  arg : ParseNode,
  name : String,
) -> Array[ArrayColumn] raise ParseFailure {
  let nodes = match arg {
    OrdGroup(body~, ..) => body
    _ => [arg]
  }
  let columns : Array[ArrayColumn] = []
  for node in nodes {
    let text = match node {
      Atom(text~, ..)
      | MathOrd(text~, ..)
      | TextOrd(text~, ..)
      | Spacing(text~, ..) => text
      _ =>
        raise InvalidArgument(
          message="Unknown column alignment in " + name,
          loc=None,
        )
    }
    match text {
      "l" | "c" | "r" =>
        columns.push(AlignColumn(alignment=text, pre_gap=0.0, post_gap=0.0))
      "|" | ":" => columns.push(SeparatorColumn(separator=text))
      _ =>
        raise InvalidArgument(
          message="Unknown column alignment: " + text,
          loc=None,
        )
    }
  }
  columns
}

///|
fn array_environment_handler(
  context : EnvironmentContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let columns = array_columns(
    require_function_arg(args, 0, "\\begin{" + context.env_name + "}"),
    context.env_name,
  )
  (context.parse_array)({
    columns: Some(columns),
    array_stretch: 1.0,
    hskip_before_and_after: true,
    cell_style: if context.env_name == "darray" {
      DisplayStyle
    } else {
      TextStyle
    },
    max_columns: Some(columns.length()),
    single_row: false,
    auto_tag: None,
    leqno: false,
    add_jot: false,
    column_separation_type: None,
  })
}

///|
let builtin_environments : Map[String, EnvironmentSpec] = Map([
  ("array", EnvironmentSpec::make(1, array_environment_handler)),
  ("darray", EnvironmentSpec::make(1, array_environment_handler)),
  ("matrix", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("pmatrix", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("bmatrix", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("Bmatrix", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("vmatrix", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("Vmatrix", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("matrix*", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("pmatrix*", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("bmatrix*", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("Bmatrix*", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("vmatrix*", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("Vmatrix*", EnvironmentSpec::make(0, matrix_environment_handler)),
  ("smallmatrix", EnvironmentSpec::make(0, smallmatrix_environment_handler)),
  ("cases", EnvironmentSpec::make(0, cases_environment_handler)),
  ("dcases", EnvironmentSpec::make(0, cases_environment_handler)),
  ("rcases", EnvironmentSpec::make(0, cases_environment_handler)),
  ("drcases", EnvironmentSpec::make(0, cases_environment_handler)),
  ("equation", EnvironmentSpec::make(0, equation_environment_handler)),
  ("equation*", EnvironmentSpec::make(0, equation_environment_handler)),
  ("aligned", EnvironmentSpec::make(0, aligned_environment_handler)),
  ("align", EnvironmentSpec::make(0, aligned_environment_handler)),
  ("align*", EnvironmentSpec::make(0, aligned_environment_handler)),
  ("split", EnvironmentSpec::make(0, aligned_environment_handler)),
  ("gathered", EnvironmentSpec::make(0, gather_environment_handler)),
  ("gather", EnvironmentSpec::make(0, gather_environment_handler)),
  ("gather*", EnvironmentSpec::make(0, gather_environment_handler)),
  ("alignat", EnvironmentSpec::make(1, alignat_environment_handler)),
  ("alignat*", EnvironmentSpec::make(1, alignat_environment_handler)),
  ("alignedat", EnvironmentSpec::make(1, alignat_environment_handler)),
])

///|
fn lookup_environment(name : String) -> EnvironmentSpec? {
  builtin_environments.get(name)
}
