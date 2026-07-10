///|
priv enum ArgType {
  OriginalArg
}

///|
type FunctionHandler = (Parser, Array[ParseNode], Array[ParseNode?]) -> ParseResult[
  ParseNode?,
]

///|
priv struct FunctionSpec {
  num_args : Int
  num_optional_args : Int
  arg_types : Array[ArgType]
  allowed_in_argument : Bool
  allowed_in_text : Bool
  allowed_in_math : Bool
  handler : FunctionHandler
}

///|
fn lookup_function(name : String) -> FunctionSpec? {
  match name {
    "\\relax" => Some(relax_spec())
    _ => None
  }
}

///|
fn is_registered_function(name : String) -> Bool {
  lookup_function(name) is Some(_)
}

///|
fn relax_spec() -> FunctionSpec {
  {
    num_args: 0,
    num_optional_args: 0,
    arg_types: [],
    allowed_in_argument: true,
    allowed_in_text: true,
    allowed_in_math: true,
    handler: relax_handler,
  }
}

///|
fn relax_handler(
  parser : Parser,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseResult[ParseNode?] {
  let _ = parser
  Ok(None)
}
