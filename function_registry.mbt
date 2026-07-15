///|
priv enum ArgType {
  OriginalArg
}

///|
type FunctionHandler = (Parser, Array[ParseNode], Array[ParseNode?]) -> ParseNode? raise ParseFailure

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
    "\\verb" => Some(verb_spec())
    _ => None
  }
}

///|
fn verb_spec() -> FunctionSpec {
  {
    num_args: 0,
    num_optional_args: 0,
    arg_types: [],
    allowed_in_argument: false,
    allowed_in_text: true,
    allowed_in_math: true,
    handler: verb_handler,
  }
}

///|
fn verb_handler(
  _parser : Parser,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode? raise ParseFailure {
  raise InvalidArgument(
    message="\\verb ended by end of line instead of matching delimiter",
    loc=None,
  )
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
    handler: (parser, args, opt_args) => relax_handler(parser, args, opt_args),
  }
}

///|
fn relax_handler(
  parser : Parser,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode? {
  let _ = parser
  None
}
