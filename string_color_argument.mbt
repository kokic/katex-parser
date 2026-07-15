///|
fn Parser::parse_string_group(
  self : Parser,
  optional : Bool,
) -> Token? raise ParseFailure {
  match self.gullet.scan_argument(optional) {
    None => None
    Some(arg_token) => {
      let builder = StringBuilder()
      for ;; {
        let token = self.fetch()
        if token.text == "EOF" {
          self.consume()
          arg_token.text = builder.to_string()
          break Some(arg_token)
        }
        builder.write_string(token.text)
        self.consume()
      }
    }
  }
}

///|
fn is_ascii_hex_digit(code : UInt16) -> Bool {
  (code >= '0' && code <= '9') ||
  (code >= 'a' && code <= 'f') ||
  (code >= 'A' && code <= 'F')
}

///|
fn all_code_units(text : String, predicate : (UInt16) -> Bool) -> Bool {
  guard !text.is_empty() else { false }
  for index in 0..<text.length() {
    guard predicate(text[index]) else { return false }
  }
  true
}

///|
fn normalized_color(text : String) -> String? {
  if text.length() > 0 && text[0] == '#' {
    let digits = text.unsafe_substring(start=1, end=text.length())
    if (
        digits.length() == 3 ||
        digits.length() == 4 ||
        digits.length() == 6 ||
        digits.length() == 8
      ) &&
      all_code_units(digits, is_ascii_hex_digit) {
      Some(text)
    } else {
      None
    }
  } else if text.length() == 6 && all_code_units(text, is_ascii_hex_digit) {
    Some("#" + text)
  } else if all_code_units(text, is_ascii_alphabetic) {
    Some(text)
  } else {
    None
  }
}

///|
fn Parser::parse_color_group(
  self : Parser,
  optional : Bool,
) -> ParseNode? raise ParseFailure {
  match self.parse_string_group(optional) {
    None => None
    Some(token) =>
      match normalized_color(token.text) {
        Some(color) => Some(ColorToken(mode=self.mode, color~))
        None =>
          raise InvalidArgument(
            message="Invalid color: '" + token.text + "'",
            loc=token.loc,
          )
      }
  }
}
