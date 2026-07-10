///|
pub(all) enum ParseFailure {
  UnexpectedCharacter(message~ : String, loc~ : SourceLocation?)
  ExpectedToken(expected~ : String, actual~ : Diagnostic)
  UndefinedControlSequence(name~ : String, loc~ : SourceLocation?)
  InvalidArgument(message~ : String, loc~ : SourceLocation?)
  DoubleSuperscript(loc~ : SourceLocation?)
  DoubleSubscript(loc~ : SourceLocation?)
  ExpectedGroupAfter(symbol~ : String, loc~ : SourceLocation?)
  FunctionNotAllowed(
    func_name~ : String,
    context~ : String,
    loc~ : SourceLocation?
  )
  MissingFunctionHandler(func_name~ : String, loc~ : SourceLocation?)
  TooManyExpansions(limit~ : Int)
  InternalInvariant(message~ : String)
} derive(Debug, ToJson, Eq)

///|
pub type ParseResult[T] = Result[T, ParseFailure]

///|
pub(all) struct Diagnostic {
  text : String
  loc : SourceLocation?
} derive(Debug, ToJson, Eq)

///|
fn Diagnostic::from_token(token : Token) -> Diagnostic {
  { text: token.text, loc: token.loc }
}
