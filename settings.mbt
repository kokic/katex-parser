///|
pub(all) enum StrictResponse {
  Ignore
  Warn
  Error
}

///|
pub type StrictHandler = (String, String, SourceLocation?) -> StrictResponse raise ParseFailure

///|
pub(all) enum Strictness {
  Ignore
  Warn
  Error
  Callback(StrictHandler)
}

///|
pub type StrictWarningHandler = (String) -> Unit

///|
pub(all) enum TrustContext {
  UrlTrust(command~ : String, url~ : String, protocol~ : String?)
  HtmlClass(class~ : String)
  HtmlId(id~ : String)
  HtmlStyle(style~ : String)
  HtmlData(attributes~ : Map[String, String])
}

///|
pub type TrustHandler = (TrustContext) -> Bool

///|
pub(all) enum TrustPolicy {
  Untrusted
  Trusted
  Callback(TrustHandler)
}

///|
pub struct Settings {
  throw_on_error : Bool
  display_mode : Bool
  leqno : Bool
  error_color : String
  color_is_text_color : Bool
  max_expand : Int
  global_group : Bool
  macros : Map[String, String]
  strict : Strictness
  strict_warning_handler : StrictWarningHandler?
  trust : TrustPolicy
}

///|
pub fn Settings::make(
  throw_on_error? : Bool = true,
  display_mode? : Bool = false,
  leqno? : Bool = false,
  error_color? : String = "#cc0000",
  color_is_text_color? : Bool = false,
  max_expand? : Int = 1000,
  global_group? : Bool = false,
  macros? : Map[String, String] = Map([]),
  strict? : Strictness = Ignore,
  strict_warning_handler? : StrictWarningHandler,
  trust? : TrustPolicy = Untrusted,
) -> Settings {
  {
    throw_on_error,
    display_mode,
    leqno,
    error_color,
    color_is_text_color,
    max_expand,
    global_group,
    macros,
    strict,
    strict_warning_handler,
    trust,
  }
}

///|
pub fn Settings::default() -> Settings {
  Settings::make()
}

///|
fn Settings::macro_definitions(self : Settings) -> Map[String, MacroDefinition] {
  let definitions : Map[String, MacroDefinition] = Map([])
  for name, expansion in self.macros {
    definitions[name] = MacroDefinition::text(expansion)
  }
  definitions
}

///|
fn Settings::use_strict_behavior(
  self : Settings,
  error_code : String,
  error_message : String,
  token : Token?,
) -> Bool {
  match
    strict_response(
      self.strict,
      error_code,
      error_message,
      token_location(token),
    ) {
    Error => true
    Warn => {
      let warning = "LaTeX-incompatible input and strict mode is set to 'warn': \{error_message} [\{error_code}]"
      match self.strict_warning_handler {
        Some(handler) => handler(warning)
        None => ()
      }
      false
    }
    Ignore => false
  }
}

///|
fn ascii_lower(text : String) -> String {
  let builder = StringBuilder()
  for _, code in text {
    builder.write_char(code.to_ascii_lowercase())
  }
  builder.to_string()
}

///|
fn url_starts_with(url : String, offset : Int, prefix : String) -> Bool {
  offset + prefix.length() <= url.length() &&
  url.unsafe_substring(start=offset, end=offset + prefix.length()) == prefix
}

///|
fn encoded_colon_at(url : String, offset : Int) -> Bool {
  if url_starts_with(ascii_lower(url), offset, "&colon") {
    return true
  }
  guard url_starts_with(url, offset, "&#") else { false }
  let mut index = offset + 2
  if index < url.length() && (url[index] == 'x' || url[index] == 'X') {
    index = index + 1
    while index < url.length() && url[index] == '0' {
      index = index + 1
    }
    url_starts_with(ascii_lower(url), index, "3a")
  } else {
    while index < url.length() && url[index] == '0' {
      index = index + 1
    }
    url_starts_with(url, index, "58")
  }
}

///|
fn url_protocol(url : String) -> String? {
  let mut index = 0
  while index < url.length() && url[index] <= 0x20 {
    index = index + 1
  }
  let start = index
  while index < url.length() {
    let code = url[index]
    if code == ':' {
      guard index > start else { return None }
      let scheme = url.unsafe_substring(start~, end=index)
      guard (scheme[0] >= 'A' && scheme[0] <= 'Z') ||
        (scheme[0] >= 'a' && scheme[0] <= 'z') else {
        return None
      }
      for _, char in scheme {
        guard (char >= 'A' && char <= 'Z') ||
          (char >= 'a' && char <= 'z') ||
          (char >= '0' && char <= '9') ||
          char == '+' ||
          char == '-' ||
          char == '.' else {
          return None
        }
      }
      return Some(ascii_lower(scheme))
    }
    if code == '/' || code == '#' || code == '?' {
      return Some("_relative")
    }
    if code == '&' && encoded_colon_at(url, index) {
      return None
    }
    index = index + 1
  }
  Some("_relative")
}

///|
fn Settings::is_trusted(self : Settings, context : TrustContext) -> Bool {
  let context = match context {
    UrlTrust(command~, url~, ..) =>
      match url_protocol(url) {
        None => return false
        Some(protocol) => UrlTrust(command~, url~, protocol=Some(protocol))
      }
    HtmlClass(..) | HtmlId(..) | HtmlStyle(..) | HtmlData(..) => context
  }
  match self.trust {
    Untrusted => false
    Trusted => true
    Callback(handler) => handler(context)
  }
}

///|
fn strict_response(
  strictness : Strictness,
  error_code : String,
  error_message : String,
  loc : SourceLocation?,
) -> StrictResponse {
  match strictness {
    Ignore => Ignore
    Warn => Warn
    Error => Error
    Callback(handler) =>
      handler(error_code, error_message, loc) catch {
        _ => Error
      }
  }
}

///|
fn Settings::report_nonstrict(
  self : Settings,
  error_code : String,
  error_message : String,
  token : Token?,
) -> Unit raise ParseFailure {
  match
    strict_response(
      self.strict,
      error_code,
      error_message,
      token_location(token),
    ) {
    Ignore => ()
    Warn => {
      let warning = "LaTeX-incompatible input and strict mode is set to 'warn': " +
        error_message +
        " [" +
        error_code +
        "]"
      match self.strict_warning_handler {
        Some(handler) => handler(warning)
        None => ()
      }
    }
    Error =>
      raise InvalidArgument(
        message="LaTeX-incompatible input and strict mode is set to 'error': " +
          error_message +
          " [" +
          error_code +
          "]",
        loc=token_location(token),
      )
  }
}
