///|
/// Configuration for the Unicode renderer.
pub struct RenderConfig {
  fraction_slash : String
  spacing : @backend.SpacingSpec
} derive(Eq)

///|
/// Unicode text spacing: regular spaces for thick/medium, empty for thin.
pub fn unicode_text_spacing() -> @backend.SpacingSpec {
  { thick: " ", medium: " ", thin: "" }
}

///|
pub fn RenderConfig::make(
  fraction_slash? : String = "∕",
  spacing? : @backend.SpacingSpec = unicode_text_spacing(),
) -> RenderConfig {
  { fraction_slash, spacing }
}

///|
pub fn RenderConfig::default() -> RenderConfig {
  RenderConfig::make()
}

///|
priv struct RenderState {
  in_display : Bool
  in_tight : Bool
  config : RenderConfig
}
