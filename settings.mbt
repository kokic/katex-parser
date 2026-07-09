///|
pub(all) struct Settings {
  display_mode : Bool
  throw_on_error : Bool
  error_color : String
  max_expand : Int
  global_group : Bool
  color_is_text_color : Bool
  strict : Bool
  leqno : Bool
  macros : Map[String, MacroDefinition]
} derive(Debug)

///|
pub fn Settings::default() -> Settings {
  {
    display_mode: false,
    throw_on_error: true,
    error_color: "#cc0000",
    max_expand: 1000,
    global_group: false,
    color_is_text_color: false,
    strict: false,
    leqno: false,
    macros: {},
  }
}
