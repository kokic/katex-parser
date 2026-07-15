///|
type LexerReporter = (String, String) -> Unit raise ParseFailure

///|
priv struct Lexer {
  input : String
  mut offset : Int
  catcodes : Map[String, Int]
  report_nonstrict : LexerReporter
}

///|
fn Lexer::make(
  input : String,
  report_nonstrict? : LexerReporter = (_code, _message) => (),
) -> Lexer {
  let lexer : Lexer = { input, offset: 0, catcodes: Map([]), report_nonstrict }
  lexer.set_catcode("%", 14)
  lexer.set_catcode("~", 13)
  lexer
}

///|
fn Lexer::set_catcode(self : Lexer, char : String, code : Int) -> Unit {
  self.catcodes[char] = code
}

///|
fn Lexer::catcode(self : Lexer, char : String) -> Int? {
  self.catcodes.get(char)
}

///|
fn is_space_code_unit(c : UInt16) -> Bool {
  c == ' ' || c == '\r' || c == '\n' || c == '\t'
}

///|
fn is_horizontal_space_code_unit(c : UInt16) -> Bool {
  c == ' ' || c == '\r' || c == '\t'
}

///|
fn is_ascii_letter(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '@'
}

///|
fn is_ascii_alphabetic(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_combining_diacritical_mark(c : UInt16) -> Bool {
  c >= 0x0300 && c <= 0x036f
}

///|
fn is_high_surrogate(c : UInt16) -> Bool {
  c >= 0xd800 && c <= 0xdbff
}

///|
fn is_low_surrogate(c : UInt16) -> Bool {
  c >= 0xdc00 && c <= 0xdfff
}

///|
fn is_regular_code_unit(c : UInt16) -> Bool {
  (c >= 0x0021 && c <= 0x005b) ||
  (c >= 0x005d && c <= 0x2027) ||
  (c >= 0x202a && c <= 0xd7ff) ||
  (c >= 0xf900 && c <= 0xffff)
}

///|
fn is_js_line_terminator(c : UInt16) -> Bool {
  c == '\n' || c == '\r' || c == 0x2028 || c == 0x2029
}

///|
fn token_text(input : String, start : Int, end : Int) -> String {
  input.unsafe_substring(start~, end~)
}

///|
fn token_at(input : String, start : Int, end : Int, text : String) -> Token {
  Token::make(text, loc=SourceLocation::make(input, start~, end~))
}

///|
fn combining_marks_end(input : String, offset : Int) -> Int {
  let len = input.length()
  for i = offset; i < len; i = i + 1 {
    if !is_combining_diacritical_mark(input[i]) {
      break i
    }
  } nobreak {
    len
  }
}

///|
fn whitespace_end(input : String, offset : Int) -> Int {
  let len = input.length()
  for i = offset; i < len; i = i + 1 {
    if !is_space_code_unit(input[i]) {
      break i
    }
  } nobreak {
    len
  }
}

///|
fn horizontal_space_end(input : String, offset : Int) -> Int {
  let len = input.length()
  for i = offset; i < len; i = i + 1 {
    if !is_horizontal_space_code_unit(input[i]) {
      break i
    }
  } nobreak {
    len
  }
}

///|
fn control_space_end(input : String, start : Int) -> Int? {
  let len = input.length()
  if start + 1 >= len {
    None
  } else if input[start + 1] == '\n' {
    Some(horizontal_space_end(input, start + 2))
  } else if is_horizontal_space_code_unit(input[start + 1]) {
    let spaces_end = horizontal_space_end(input, start + 1)
    let after_newline = if spaces_end < len && input[spaces_end] == '\n' {
      spaces_end + 1
    } else {
      spaces_end
    }
    Some(horizontal_space_end(input, after_newline))
  } else {
    None
  }
}

///|
fn starts_with_at(input : String, offset : Int, prefix : String) -> Bool {
  let prefix_len = prefix.length()
  offset + prefix_len <= input.length() &&
  input.unsafe_substring(start=offset, end=offset + prefix_len) == prefix
}

///|
fn verb_end(input : String, start : Int, starred : Bool) -> Int? {
  let prefix = if starred { "\\verb*" } else { "\\verb" }
  if !starts_with_at(input, start, prefix) {
    return None
  }
  let delimiter_offset = start + prefix.length()
  if delimiter_offset >= input.length() {
    return None
  }
  let delimiter = input[delimiter_offset]
  if !starred && (delimiter == '*' || is_ascii_alphabetic(delimiter)) {
    return None
  }
  for i = delimiter_offset + 1; i < input.length(); i = i + 1 {
    let c = input[i]
    if c == delimiter {
      break Some(i + 1)
    } else if is_js_line_terminator(c) {
      break None
    }
  } nobreak {
    None
  }
}

///|
fn control_word_end(input : String, start : Int) -> (Int, Int)? {
  let len = input.length()
  if start + 1 >= len || !is_ascii_letter(input[start + 1]) {
    None
  } else {
    let raw_end = for i = start + 2; i < len; i = i + 1 {
      if !is_ascii_letter(input[i]) {
        break i
      }
    } nobreak {
      len
    }
    Some((raw_end, whitespace_end(input, raw_end)))
  }
}

///|
fn next_line_start(input : String, offset : Int) -> Int? {
  for i = offset; i < input.length(); i = i + 1 {
    if input[i] == '\n' {
      break Some(i + 1)
    }
  } nobreak {
    None
  }
}

///|
fn unexpected_character(input : String, offset : Int) -> ParseFailure {
  let text = token_text(input, offset, offset + 1)
  UnexpectedCharacter(
    message="Unexpected character: '" + text + "'",
    loc=Some(SourceLocation::make(input, start=offset, end=offset + 1)),
  )
}

///|
fn Lexer::match_token(self : Lexer) -> Token raise ParseFailure {
  let input = self.input
  let len = input.length()
  let start = self.offset
  let c = input[start]
  if is_space_code_unit(c) {
    let end = whitespace_end(input, start + 1)
    self.offset = end
    token_at(input, start, end, " ")
  } else if c == '\\' {
    match control_space_end(input, start) {
      Some(end) => {
        self.offset = end
        token_at(input, start, end, "\\ ")
      }
      None =>
        match verb_end(input, start, true) {
          Some(end) => {
            self.offset = end
            token_at(input, start, end, token_text(input, start, end))
          }
          None =>
            match verb_end(input, start, false) {
              Some(end) => {
                self.offset = end
                token_at(input, start, end, token_text(input, start, end))
              }
              None =>
                match control_word_end(input, start) {
                  Some((raw_end, end)) => {
                    self.offset = end
                    token_at(
                      input,
                      start,
                      end,
                      token_text(input, start, raw_end),
                    )
                  }
                  None =>
                    if start + 1 < len &&
                      !is_high_surrogate(input[start + 1]) &&
                      !is_low_surrogate(input[start + 1]) {
                      let end = start + 2
                      self.offset = end
                      token_at(input, start, end, token_text(input, start, end))
                    } else {
                      raise unexpected_character(input, start)
                    }
                }
            }
        }
    }
  } else if is_regular_code_unit(c) {
    let end = combining_marks_end(input, start + 1)
    self.offset = end
    token_at(input, start, end, token_text(input, start, end))
  } else if is_high_surrogate(c) &&
    start + 1 < len &&
    is_low_surrogate(input[start + 1]) {
    let end = combining_marks_end(input, start + 2)
    self.offset = end
    token_at(input, start, end, token_text(input, start, end))
  } else {
    raise unexpected_character(input, start)
  }
}

///|
fn Lexer::lex(self : Lexer) -> Token raise ParseFailure {
  for ;; {
    if self.offset == self.input.length() {
      break Token::eof(self.input, self.offset)
    }
    let token = self.match_token()
    if self.catcodes.get(token.text) == Some(14) {
      match next_line_start(self.input, self.offset) {
        Some(offset) => {
          self.offset = offset
          continue
        }
        None => {
          self.offset = self.input.length()
          (self.report_nonstrict)(
            "commentAtEnd", "% comment has no terminating newline; LaTeX would fail because of commenting the end of math mode (e.g. $)",
          )
          continue
        }
      }
    } else {
      break token
    }
  }
}
