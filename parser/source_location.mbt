///|
pub(all) struct SourceLocation {
  input : String
  start : Int
  end : Int
} derive(Debug, ToJson, Eq)

///|
pub fn SourceLocation::make(
  input : String,
  start~ : Int,
  end~ : Int,
) -> SourceLocation {
  { input, start, end }
}

///|
fn SourceLocation::range(
  start_loc : SourceLocation,
  end_loc : SourceLocation,
) -> SourceLocation {
  { input: start_loc.input, start: start_loc.start, end: end_loc.end }
}
