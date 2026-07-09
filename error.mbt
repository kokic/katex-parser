///|
pub(all) enum ParseFailure {
  UnexpectedCharacter(message~ : String, loc~ : SourceLocation?)
  ExpectedToken(expected~ : String, actual~ : Token)
  UndefinedControlSequence(name~ : String, token~ : Token)
  InvalidArgument(message~ : String, token~ : Token?)
  TooManyExpansions(limit~ : Int)
  Generic(message~ : String, token~ : Token?)
} derive(Debug, ToJson, Eq)

///|
pub type ParseResult[T] = Result[T, ParseFailure]
