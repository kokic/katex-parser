///|
priv struct Lexer {
  input : String
  mut offset : Int
}

///|
fn Lexer::make(input : String) -> Lexer {
  { input, offset: 0 }
}

///|
fn is_space_code_unit(c : UInt16) -> Bool {
  c == ' ' || c == '\r' || c == '\n' || c == '\t'
}

///|
fn is_ascii_letter(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '@'
}

///|
fn token_text(input : String, start : Int, end : Int) -> String {
  input.unsafe_substring(start~, end~)
}

///|
fn char_end_offset(input : String, start : Int) -> ParseResult[Int] {
  match input.get_char(start) {
    Some(ch) => {
      let next = start + ch.to_string().length()
      Ok(next)
    }
    None =>
      Err(
        UnexpectedCharacter(
          message="Invalid UTF-16 character boundary",
          loc=Some(SourceLocation::make(input, start~, end=start + 1)),
        ),
      )
  }
}

///|
fn token_at(input : String, start : Int, end : Int, text : String) -> Token {
  Token::make(text, loc=SourceLocation::make(input, start~, end~))
}

///|
fn find_verb_end(input : String, start : Int, delim : UInt16) -> Int? {
  for i = start; i < input.length(); i = i + 1 {
    if input[i] == delim {
      break Some(i + 1)
    }
  } nobreak {
    None
  }
}

///|
fn find_next_line_start(input : String, start : Int) -> Int {
  for i = start; i < input.length(); i = i + 1 {
    if input[i] == '\n' {
      break i + 1
    }
  } nobreak {
    input.length()
  }
}

///|
fn starts_with_at(input : String, offset : Int, prefix : String) -> Bool {
  let prefix_len = prefix.length()
  if offset + prefix_len > input.length() {
    false
  } else {
    input.unsafe_substring(start=offset, end=offset + prefix_len) == prefix
  }
}

///|
fn Lexer::lex(self : Lexer) -> ParseResult[Token] {
  let input = self.input
  let len = input.length()
  if self.offset >= len {
    Ok(Token::eof(input, len))
  } else {
    let start = self.offset
    let c = input[start]
    if is_space_code_unit(c) {
      for i = start; i < len; i = i + 1 {
        if !is_space_code_unit(input[i]) {
          self.offset = i
          break Ok(token_at(input, start, i, " "))
        }
      } nobreak {
        self.offset = len
        Ok(token_at(input, start, len, " "))
      }
    } else if c == '%' {
      let next_offset = find_next_line_start(input, start + 1)
      self.offset = next_offset
      self.lex()
    } else if c == '\\' {
      self.lex_control(start)
    } else {
      match char_end_offset(input, start) {
        Err(err) => Err(err)
        Ok(end_offset) => {
          self.offset = end_offset
          Ok(
            token_at(
              input,
              start,
              end_offset,
              token_text(input, start, end_offset),
            ),
          )
        }
      }
    }
  }
}

///|
fn Lexer::lex_control(self : Lexer, start : Int) -> ParseResult[Token] {
  let input = self.input
  let len = input.length()
  if start + 1 >= len {
    Err(
      UnexpectedCharacter(
        message="Unexpected bare backslash",
        loc=Some(SourceLocation::make(input, start~, end=len)),
      ),
    )
  } else {
    let after = input[start + 1]
    if is_space_code_unit(after) {
      for i = start + 1; i < len; i = i + 1 {
        if !is_space_code_unit(input[i]) {
          self.offset = i
          break Ok(token_at(input, start, i, "\\ "))
        }
      } nobreak {
        self.offset = len
        Ok(token_at(input, start, len, "\\ "))
      }
    } else if is_ascii_letter(after) {
      for i = start + 1; i < len; i = i + 1 {
        if !is_ascii_letter(input[i]) {
          let raw_end = i
          let final_end = consume_trailing_spaces(input, raw_end)
          self.offset = final_end
          let text = input.unsafe_substring(start~, end=raw_end)
          break Ok(token_at(input, start, final_end, text))
        }
      } nobreak {
        self.offset = len
        let text = input.unsafe_substring(start~, end=len)
        Ok(token_at(input, start, len, text))
      }
    } else if starts_with_at(input, start, "\\verb*") && start + 6 < len {
      let delim = input[start + 6]
      match find_verb_end(input, start + 7, delim) {
        Some(end_offset) => {
          self.offset = end_offset
          Ok(
            token_at(
              input,
              start,
              end_offset,
              input.unsafe_substring(start~, end=end_offset),
            ),
          )
        }
        None => {
          self.offset = start + 6
          Ok(token_at(input, start, start + 6, "\\verb*"))
        }
      }
    } else if starts_with_at(input, start, "\\verb") && start + 5 < len {
      let delim = input[start + 5]
      match find_verb_end(input, start + 6, delim) {
        Some(end_offset) => {
          self.offset = end_offset
          Ok(
            token_at(
              input,
              start,
              end_offset,
              input.unsafe_substring(start~, end=end_offset),
            ),
          )
        }
        None => {
          self.offset = start + 5
          Ok(token_at(input, start, start + 5, "\\verb"))
        }
      }
    } else {
      self.offset = start + 2
      Ok(
        token_at(
          input,
          start,
          start + 2,
          input.unsafe_substring(start~, end=start + 2),
        ),
      )
    }
  }
}

///|
fn consume_trailing_spaces(input : String, offset : Int) -> Int {
  let len = input.length()
  for i = offset; i < len; i = i + 1 {
    if !is_space_code_unit(input[i]) {
      break i
    }
  } nobreak {
    len
  }
}
