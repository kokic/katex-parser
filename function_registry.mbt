///|
pub(all) enum ArgType {
  ColorArg
  SizeArg
  UrlArg
  MathArg
  TextArg
  HBoxArg
  RawArg
  PrimitiveArg
  OriginalArg
} derive(Debug, ToJson, Eq)

///|
pub(all) struct FunctionContext {
  func_name : String
  parser : Parser
  token : Token?
  break_on_token_text : String?
} derive(Debug)

///|
pub type FunctionHandler = (
  FunctionContext,
  Array[ParseNode],
  Array[ParseNode?],
) -> ParseResult[ParseNode]

///|
pub(all) struct FunctionSpec {
  type_name : String
  num_args : Int
  num_optional_args : Int
  arg_types : Array[ArgType]
  allowed_in_argument : Bool
  allowed_in_text : Bool
  allowed_in_math : Bool
  infix : Bool
  primitive : Bool
  handler : FunctionHandler
}

///|
pub fn registered_functions() -> Map[String, FunctionSpec] {
  { "\\relax": relax_spec() }
}

///|
fn relax_spec() -> FunctionSpec {
  {
    type_name: "internal",
    num_args: 0,
    num_optional_args: 0,
    arg_types: [],
    allowed_in_argument: true,
    allowed_in_text: true,
    allowed_in_math: true,
    infix: false,
    primitive: false,
    handler: relax_handler,
  }
}

///|
fn relax_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseResult[ParseNode] {
  Ok(Internal(mode=context.parser.mode))
}
