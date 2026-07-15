///|
fn is_ascii_digit_code_unit(code : UInt16) -> Bool {
  code >= '0' && code <= '9'
}

///|
fn skip_ascii_spaces(text : String, start : Int) -> Int {
  for index = start; index < text.length(); index = index + 1 {
    if text[index] != ' ' {
      break index
    }
  } nobreak {
    text.length()
  }
}

///|
fn size_scan_candidate(text : String) -> Bool {
  // Mirrors KaTeX's anchored regex for every intermediate token prefix.
  let len = text.length()
  let mut index = 0
  if index < len && (text[index] == '+' || text[index] == '-') {
    index = index + 1
  }
  index = skip_ascii_spaces(text, index)
  guard index < len else { true }
  if is_ascii_digit_code_unit(text[index]) {
    while index < len && is_ascii_digit_code_unit(text[index]) {
      index = index + 1
    }
    if index < len && text[index] == '.' {
      index = index + 1
      while index < len && is_ascii_digit_code_unit(text[index]) {
        index = index + 1
      }
    }
  } else if text[index] == '.' {
    index = index + 1
    while index < len && is_ascii_digit_code_unit(text[index]) {
      index = index + 1
    }
  } else {
    return false
  }
  index = skip_ascii_spaces(text, index)
  let unit_start = index
  while index < len && text[index] >= 'a' && text[index] <= 'z' {
    index = index + 1
  }
  guard index - unit_start <= 2 else { false }
  index = skip_ascii_spaces(text, index)
  index == len
}

///|
fn Parser::parse_size_regex_group(self : Parser) -> Token raise ParseFailure {
  let first_token = self.fetch()
  let mut last_token = first_token
  let builder = StringBuilder()
  for ;; {
    let token = self.fetch()
    guard token.text != "EOF" else { break }
    let candidate = builder.to_string() + token.text
    guard size_scan_candidate(candidate) else { break }
    builder.write_string(token.text)
    last_token = token
    self.consume()
  }
  let text = builder.to_string()
  guard !text.is_empty() else {
    raise InvalidArgument(
      message="Invalid size: '" + first_token.text + "'",
      loc=first_token.loc,
    )
  }
  first_token.range(last_token, text)
}

///|
fn parse_decimal(text : String) -> Double raise ParseFailure {
  @string.from_str(text) catch {
    _ =>
      raise InternalInvariant(
        message="Validated size number failed Double conversion: " + text,
      )
  }
}

///|
fn parse_size_measurement(text : String) -> Measurement? raise ParseFailure {
  // KaTeX's final measurement regex is intentionally unanchored.
  let len = text.length()
  for start in 0..<len {
    let mut index = start
    let number_builder = StringBuilder()
    if text[index] == '+' || text[index] == '-' {
      number_builder.write_string(
        text.unsafe_substring(start=index, end=index + 1),
      )
      index = index + 1
      index = skip_ascii_spaces(text, index)
    }
    let number_start = index
    while index < len && is_ascii_digit_code_unit(text[index]) {
      number_builder.write_string(
        text.unsafe_substring(start=index, end=index + 1),
      )
      index = index + 1
    }
    let digits_before_dot = index - number_start
    let mut digits_after_dot = 0
    if index < len && text[index] == '.' {
      number_builder.write_string(".")
      index = index + 1
      let fraction_start = index
      while index < len && is_ascii_digit_code_unit(text[index]) {
        number_builder.write_string(
          text.unsafe_substring(start=index, end=index + 1),
        )
        index = index + 1
      }
      digits_after_dot = index - fraction_start
    }
    guard digits_before_dot > 0 || digits_after_dot > 0 else { continue }
    index = skip_ascii_spaces(text, index)
    guard index + 2 <= len else { continue }
    let first = text[index]
    let second = text[index + 1]
    guard first >= 'a' && first <= 'z' && second >= 'a' && second <= 'z' else {
      continue
    }
    let unit = text.unsafe_substring(start=index, end=index + 2)
    return Some({ number: parse_decimal(number_builder.to_string()), unit })
  }
  None
}

///|
fn valid_size_unit(unit : String) -> Bool {
  match unit {
    "pt"
    | "mm"
    | "cm"
    | "in"
    | "bp"
    | "pc"
    | "dd"
    | "cc"
    | "nd"
    | "nc"
    | "sp"
    | "px"
    | "ex"
    | "em"
    | "mu" => true
    _ => false
  }
}

///|
fn Parser::parse_size_group(
  self : Parser,
  optional : Bool,
) -> ParseNode? raise ParseFailure {
  self.gullet.consume_spaces()
  let parsed = if !optional && self.gullet.future().text != "{" {
    Some(self.parse_size_regex_group())
  } else {
    self.parse_string_group(optional)
  }
  match parsed {
    None => None
    Some(token) => {
      let mut text = token.text
      let is_blank = !optional && text.is_empty()
      if is_blank {
        text = "0pt"
      }
      match parse_size_measurement(text) {
        None =>
          raise InvalidArgument(
            message="Invalid size: '" + text + "'",
            loc=token.loc,
          )
        Some(value) => {
          guard valid_size_unit(value.unit) else {
            raise InvalidArgument(
              message="Invalid unit: '" + value.unit + "'",
              loc=token.loc,
            )
          }
          Some(Size(mode=self.mode, value~, is_blank~))
        }
      }
    }
  }
}
