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
  let lexer : Lexer = { input, offset: 0, catcodes: Map([]), report_nonstrict, }
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
fn is_ascii_alphabetic(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_combining_diacritical_mark(c : UInt16) -> Bool {
  c >= 0x0300 && c <= 0x036f
}

///|
fn is_js_line_terminator(c : UInt16) -> Bool {
  c == '\n' || c == '\r' || c == 0x2028 || c == 0x2029
}

///|
fn verb_end(input : String, start : Int, starred : Bool) -> Int? {
  let prefix = if starred { "\\verb*" } else { "\\verb" }
  if !input[start:].has_prefix(prefix[:]) {
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
  let text = input.unsafe_substring(start=offset, end=offset + 1)
  UnexpectedCharacter(
    message="Unexpected character: '\{text}'",
    loc=Some(SourceLocation::make(input, start=offset, end=offset + 1)),
  )
}

///|
fn Lexer::match_token(self : Lexer) -> Token raise ParseFailure {
  let input = self.input
  let start = self.offset
  // A verb delimiter can leave the cursor inside a UTF-16 surrogate pair.
  // Reject that position instead of snapping it forward with a clamped slice.
  guard input.get_view(start~) is Some(remaining) else {
    raise unexpected_character(input, start)
  }
  // The closing verb delimiter depends on the input and needs a manual scan.
  let (text, end) = if verb_end(input, start, true) is Some(end) {
    (input.unsafe_substring(start~, end~), end)
  } else if verb_end(input, start, false) is Some(end) {
    (input.unsafe_substring(start~, end~), end)
  } else {
    // Preserve KaTeX's ordered alternatives, all anchored at the current offset.
    lexmatch remaining {
      (re"^[ \r\n\t]+", after=rest) => (" ", rest.start_offset())
      (re"^\\(\n|[ \r\t]+\n?)[ \r\t]*", after=rest) =>
        ("\\ ", rest.start_offset())
      (
        re"^[\u{0021}-\u{005b}\u{005d}-\u{2027}\u{202a}-\u{d7ff}\u{f900}-\u{10ffff}][\u{0300}-\u{036f}]*" as text,
        after=rest,
      ) => (text.to_owned(), rest.start_offset())
      ((re"^\\[a-zA-Z@]+" as text) + re"[ \r\n\t]*", after=rest) =>
        (text.to_owned(), rest.start_offset())
      (re"^\\[\u{0000}-\u{d7ff}\u{e000}-\u{ffff}]" as text, after=rest) =>
        (text.to_owned(), rest.start_offset())
      _ => raise unexpected_character(input, start)
    }
  }
  self.offset = end
  Token::make(text, loc=SourceLocation::make(input, start~, end~))
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
