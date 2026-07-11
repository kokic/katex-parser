///|
pub(all) struct Settings {
  throw_on_error : Bool
  error_color : String
  max_expand : Int
  global_group : Bool
  macros : Map[String, MacroDefinition]
} derive(Debug)

///|
pub fn Settings::default() -> Settings {
  {
    throw_on_error: true,
    error_color: "#cc0000",
    max_expand: 1000,
    global_group: false,
    macros: Map([]),
  }
}
