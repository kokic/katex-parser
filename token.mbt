///|
priv struct Token {
  text : String
  loc : SourceLocation?
}

///|
fn Token::make(text : String, loc? : SourceLocation) -> Token {
  { text, loc }
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
