///|
pub(all) enum ParseFailure {
  UnexpectedCharacter(message~ : String, loc~ : SourceLocation?)
  ExpectedToken(expected~ : String, actual~ : Token)
  UndefinedControlSequence(name~ : String, token~ : Token)
  InvalidArgument(message~ : String, token~ : Token?)
  DoubleSuperscript(token~ : Token)
  DoubleSubscript(token~ : Token)
  ExpectedGroupAfter(symbol~ : String, token~ : Token)
  FunctionNotAllowed(func_name~ : String, context~ : String, token~ : Token)
  MissingFunctionHandler(func_name~ : String, token~ : Token?)
  UnsupportedFeature(feature~ : String, token~ : Token?)
  TooManyExpansions(limit~ : Int)
  InternalInvariant(message~ : String)
} derive(Debug, ToJson, Eq)

///|
pub type ParseResult[T] = Result[T, ParseFailure]
