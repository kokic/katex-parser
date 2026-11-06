///|
#derive(Debug, ToJson, Eq)
pub(all) suberror ParseFailure {
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
  TooManyExpansions(limit~ : Int32)
  InternalInvariant(message~ : String)
}

///|
fn[T] capture_parse_result(
  operation : () -> T raise ParseFailure,
) -> Result[T, ParseFailure] {
  Ok(operation()) catch {
    err => Err(err)
  }
}

///|
#derive(Debug, ToJson, Eq)
pub(all) struct Diagnostic {
  text : String
  loc : SourceLocation?
}

///|
fn Diagnostic::from_token(token : Token) -> Diagnostic {
  { text: token.text, loc: token.loc, }
}
