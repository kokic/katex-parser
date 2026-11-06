///|
#derive(Debug, ToJson, Eq)
pub(all) struct SourceLocation {
  input : String
  start : Int32
  end : Int32
}

///|
pub fn SourceLocation::make(
  input : String,
  start~ : Int32,
  end~ : Int32,
) -> SourceLocation {
  { input, start, end, }
}

///|
fn SourceLocation::range(
  start_loc : SourceLocation,
  end_loc : SourceLocation,
) -> SourceLocation {
  { input: start_loc.input, start: start_loc.start, end: end_loc.end, }
}
