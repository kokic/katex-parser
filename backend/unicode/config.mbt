///|
/// Configuration for the Unicode renderer.
pub struct RenderConfig {
  fraction_slash : String
} derive(Eq)

///|
pub fn RenderConfig::make(fraction_slash? : String = "∕") -> RenderConfig {
  { fraction_slash, }
}

///|
pub fn RenderConfig::default() -> RenderConfig {
  RenderConfig::make()
}

///|
priv struct RenderState {
  in_display : Bool
  config : RenderConfig
}
