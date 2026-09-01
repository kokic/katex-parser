///|
pub(all) struct ArrayEnvironmentOptions {
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
pub(all) struct EnvironmentContext {
  mode : Mode
  display_mode : Bool
  leqno : Bool
  env_name : String
  parse_array : (ArrayEnvironmentOptions) -> ParseNode raise ParseFailure
  parse_matrix_alignment : () -> String? raise ParseFailure
  parse_cd : () -> ParseNode raise ParseFailure
}

///|
pub type EnvironmentHandler = (
  EnvironmentContext,
  Array[ParseNode],
  Array[ParseNode?],
) -> ParseNode raise ParseFailure

///|
pub(all) struct EnvironmentSpec {
  names : Array[String]
  num_args : Int
  num_optional_args : Int
  arg_types : Array[ArgType]
  handler : EnvironmentHandler
}

///|
pub fn EnvironmentSpec::make(
  names : Array[String],
  num_args : Int,
  num_optional_args? : Int = 0,
  arg_types? : Array[ArgType] = [],
  handler~ : EnvironmentHandler,
) -> EnvironmentSpec {
  { names, num_args, num_optional_args, arg_types, handler, }
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
  nodes.map(node => {
    let text = match node {
      Atom(text~, ..)
      | MathOrd(text~, ..)
      | TextOrd(text~, ..)
      | Spacing(text~, ..) => text
      _ =>
        raise InvalidArgument(
          message="Unknown column alignment in \{name}",
          loc=None,
        )
    }
    match text {
      "l" | "c" | "r" => AlignColumn(alignment=text, pre_gap=0.0, post_gap=0.0)
      "|" | ":" => SeparatorColumn(separator=text)
      _ =>
        raise InvalidArgument(
          message="Unknown column alignment: \{text}",
          loc=None,
        )
    }
  })
}

///|
fn array_environment_handler(
  context : EnvironmentContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let columns = array_columns(
    require_function_arg(args, 0, "\\begin{\{context.env_name}}"),
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
pub(all) struct EnvironmentRegistry {
  entries : Map[String, EnvironmentSpec]
}

///|
pub fn EnvironmentRegistry::make() -> EnvironmentRegistry {
  { entries: Map([]), }
}

///|
pub fn EnvironmentRegistry::register(
  self : EnvironmentRegistry,
  spec : EnvironmentSpec,
) -> Unit {
  for name in spec.names {
    self.entries[name] = spec
  }
}

///|
pub fn EnvironmentRegistry::get(
  self : EnvironmentRegistry,
  name : String,
) -> EnvironmentSpec? {
  self.entries.get(name)
}

///|
let builtin_environments : Array[EnvironmentSpec] = [
  EnvironmentSpec::make(
    ["array", "darray"],
    1,
    handler=array_environment_handler,
  ),
  EnvironmentSpec::make(
    [
      "matrix", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix", "matrix*",
      "pmatrix*", "bmatrix*", "Bmatrix*", "vmatrix*", "Vmatrix*",
    ],
    0,
    handler=matrix_environment_handler,
  ),
  EnvironmentSpec::make(
    ["smallmatrix"],
    0,
    handler=smallmatrix_environment_handler,
  ),
  EnvironmentSpec::make(
    ["cases", "dcases", "rcases", "drcases"],
    0,
    handler=cases_environment_handler,
  ),
  EnvironmentSpec::make(
    ["equation", "equation*"],
    0,
    handler=equation_environment_handler,
  ),
  EnvironmentSpec::make(
    ["aligned", "align", "align*", "split"],
    0,
    handler=aligned_environment_handler,
  ),
  EnvironmentSpec::make(
    ["gathered", "gather", "gather*"],
    0,
    handler=gather_environment_handler,
  ),
  EnvironmentSpec::make(
    ["alignat", "alignat*", "alignedat"],
    1,
    handler=alignat_environment_handler,
  ),
  EnvironmentSpec::make(["subarray"], 1, handler=subarray_environment_handler),
  EnvironmentSpec::make(["CD"], 0, handler=cd_environment_handler),
]

///|
/// Builds an environment registry from the builtin specs plus caller-provided
/// extension specs (which override builtins sharing the same name).
pub fn build_environment_registry(
  extra_specs : Array[EnvironmentSpec],
) -> EnvironmentRegistry {
  let registry = EnvironmentRegistry::make()
  for spec in builtin_environments {
    registry.register(spec)
  }
  for spec in extra_specs {
    registry.register(spec)
  }
  registry
}
