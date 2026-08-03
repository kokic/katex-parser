///|
/// Configuration for the Unicode renderer.
pub(all) struct RenderConfig {
  fraction_slash : String
  spacing : @backend.SpacingSpec
  line_style : LineStyle
} derive(Eq)

///|
/// Glyph style for drawn lines: fraction bars, boxes, tables, etc.
pub(all) enum LineStyle {
  Ascii
  Unicode
} derive(Eq)

///|
pub impl Default for LineStyle with fn default() {
  Unicode
}

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
  line_style? : LineStyle = Unicode,
) -> RenderConfig {
  { fraction_slash, spacing, line_style }
}

///|
/// The line character for a fraction bar under the given style.
pub fn line_style_frac_bar(style : LineStyle) -> String {
  match style {
    Ascii => "-"
    Unicode => "─"
  }
}

///|
pub impl Default for RenderConfig with fn default() {
  RenderConfig::make()
}

///|
priv struct RenderState {
  style : @katex_parser.StyleLevel
  in_display : Bool
  in_tight : Bool
  config : RenderConfig
}
