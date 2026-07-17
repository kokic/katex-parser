///|
priv struct Token {
  mut text : String
  loc : SourceLocation?
  mut noexpand : Bool
  mut treat_as_relax : Bool
}

///|
fn Token::make(text : String, loc? : SourceLocation) -> Token {
  { text, loc, noexpand: false, treat_as_relax: false }
}

///|
fn token_location(token : Token?) -> SourceLocation? {
  token.map(token => token.loc).bind(x => x)
}

///|
fn Token::eof(input : String, offset : Int) -> Token {
  Token::make("EOF", loc=SourceLocation::make(input, start=offset, end=offset))
}

///|
fn Token::range(self : Token, end_token : Token, text : String) -> Token {
  match (self.loc, end_token.loc) {
    (Some(start_loc), Some(end_loc)) =>
      Token::make(text, loc=SourceLocation::range(start_loc, end_loc))
    _ => Token::make(text)
  }
}
