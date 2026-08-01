///|
/// Configuration for the Unicode renderer.
pub struct RenderConfig {
  fraction_slash : String
  spacing : @backend.SpacingSpec
} derive(Eq)

///|
/// Unicode text spacing: regular spaces for thick/medium and after operators,
/// empty for thin.
pub fn unicode_text_spacing() -> @backend.SpacingSpec {
  { thick: " ", medium: " ", thin: "", operator: " " }
}

///|
pub fn RenderConfig::make(
  fraction_slash? : String = "∕",
  spacing? : @backend.SpacingSpec = unicode_text_spacing(),
) -> RenderConfig {
  { fraction_slash, spacing }
}

///|
pub impl Default for RenderConfig with fn default() {
  RenderConfig::make()
}

///|
priv struct RenderState {
  in_display : Bool
  in_tight : Bool
  config : RenderConfig
}
