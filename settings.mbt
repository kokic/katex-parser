///|
pub(all) enum StrictResponse {
  Ignore
  Warn
  Error
}

///|
pub type StrictHandler = (String, String, Token?) -> StrictResponse raise ParseFailure

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
pub(all) struct Settings {
  throw_on_error : Bool
  error_color : String
  color_is_text_color : Bool
  max_expand : Int
  global_group : Bool
  macros : Map[String, MacroDefinition]
  strict : Strictness
  strict_warning_handler : StrictWarningHandler?
  trust : TrustPolicy
}

///|
pub fn Settings::default() -> Settings {
  {
    throw_on_error: true,
    error_color: "#cc0000",
    color_is_text_color: false,
    max_expand: 1000,
    global_group: false,
    macros: Map([]),
    strict: Ignore,
    strict_warning_handler: None,
    trust: Untrusted,
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
    if code == '&' {
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
  token : Token?,
) -> StrictResponse {
  match strictness {
    Ignore => Ignore
    Warn => Warn
    Error => Error
    Callback(handler) =>
      handler(error_code, error_message, token) catch {
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
  match strict_response(self.strict, error_code, error_message, token) {
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
        loc=match token {
          Some(token) => token.loc
          None => None
        },
      )
  }
}
