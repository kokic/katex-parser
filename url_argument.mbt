///|
fn is_url_escape_target(code : UInt16) -> Bool {
  code == '#' ||
  code == '$' ||
  code == '%' ||
  code == '&' ||
  code == '~' ||
  code == '_' ||
  code == '^' ||
  code == '{' ||
  code == '}'
}

///|
fn unescape_url(text : String) -> String {
  let builder = StringBuilder()
  let mut segment_start = 0
  for index = 0; index < text.length(); {
    if text[index] == '\\' &&
      index + 1 < text.length() &&
      is_url_escape_target(text[index + 1]) {
      builder.write_string(
        text.unsafe_substring(start=segment_start, end=index),
      )
      builder.write_string(
        text.unsafe_substring(start=index + 1, end=index + 2),
      )
      segment_start = index + 2
      continue index + 2
    }
    continue index + 1
  } nobreak {
    builder.write_string(
      text.unsafe_substring(start=segment_start, end=text.length()),
    )
    builder.to_string()
  }
}

///|
fn Parser::parse_url_group(
  self : Parser,
  optional : Bool,
) -> ParseNode? raise ParseFailure {
  self.gullet.lexer.set_catcode("%", 13)
  self.gullet.lexer.set_catcode("~", 12)
  let parsed : Result[Token?, ParseFailure] = Ok(
    self.parse_string_group(optional),
  ) catch {
    err => Err(err)
  }
  self.gullet.lexer.set_catcode("%", 14)
  self.gullet.lexer.set_catcode("~", 13)
  match parsed {
    Err(err) => raise err
    Ok(None) => None
    Ok(Some(token)) => Some(Url(mode=self.mode, url=unescape_url(token.text)))
  }
}
