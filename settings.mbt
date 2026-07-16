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
pub(all) struct Settings {
  throw_on_error : Bool
  error_color : String
  color_is_text_color : Bool
  max_expand : Int
  global_group : Bool
  macros : Map[String, MacroDefinition]
  strict : Strictness
  strict_warning_handler : StrictWarningHandler?
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
