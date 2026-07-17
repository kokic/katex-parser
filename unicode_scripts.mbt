///|
pub(all) enum UnicodeScriptKind {
  UnicodeSubscript
  UnicodeSuperscript
} derive(Eq)

///|
pub struct UnicodeScript {
  replacement : String
  kind : UnicodeScriptKind
}

///|
let unicode_scripts : Map[String, UnicodeScript] = Map::from_array([
  ("₊", { replacement: "+", kind: UnicodeSubscript }),
  ("₋", { replacement: "-", kind: UnicodeSubscript }),
  ("₌", { replacement: "=", kind: UnicodeSubscript }),
  ("₍", { replacement: "(", kind: UnicodeSubscript }),
  ("₎", { replacement: ")", kind: UnicodeSubscript }),
  ("₀", { replacement: "0", kind: UnicodeSubscript }),
  ("₁", { replacement: "1", kind: UnicodeSubscript }),
  ("₂", { replacement: "2", kind: UnicodeSubscript }),
  ("₃", { replacement: "3", kind: UnicodeSubscript }),
  ("₄", { replacement: "4", kind: UnicodeSubscript }),
  ("₅", { replacement: "5", kind: UnicodeSubscript }),
  ("₆", { replacement: "6", kind: UnicodeSubscript }),
  ("₇", { replacement: "7", kind: UnicodeSubscript }),
  ("₈", { replacement: "8", kind: UnicodeSubscript }),
  ("₉", { replacement: "9", kind: UnicodeSubscript }),
  ("ₐ", { replacement: "a", kind: UnicodeSubscript }),
  ("ₑ", { replacement: "e", kind: UnicodeSubscript }),
  ("ₕ", { replacement: "h", kind: UnicodeSubscript }),
  ("ᵢ", { replacement: "i", kind: UnicodeSubscript }),
  ("ⱼ", { replacement: "j", kind: UnicodeSubscript }),
  ("ₖ", { replacement: "k", kind: UnicodeSubscript }),
  ("ₗ", { replacement: "l", kind: UnicodeSubscript }),
  ("ₘ", { replacement: "m", kind: UnicodeSubscript }),
  ("ₙ", { replacement: "n", kind: UnicodeSubscript }),
  ("ₒ", { replacement: "o", kind: UnicodeSubscript }),
  ("ₚ", { replacement: "p", kind: UnicodeSubscript }),
  ("ᵣ", { replacement: "r", kind: UnicodeSubscript }),
  ("ₛ", { replacement: "s", kind: UnicodeSubscript }),
  ("ₜ", { replacement: "t", kind: UnicodeSubscript }),
  ("ᵤ", { replacement: "u", kind: UnicodeSubscript }),
  ("ᵥ", { replacement: "v", kind: UnicodeSubscript }),
  ("ₓ", { replacement: "x", kind: UnicodeSubscript }),
  ("ᵦ", { replacement: "β", kind: UnicodeSubscript }),
  ("ᵧ", { replacement: "γ", kind: UnicodeSubscript }),
  ("ᵨ", { replacement: "ρ", kind: UnicodeSubscript }),
  ("ᵩ", { replacement: "ϕ", kind: UnicodeSubscript }),
  ("ᵪ", { replacement: "χ", kind: UnicodeSubscript }),
  ("⁺", { replacement: "+", kind: UnicodeSuperscript }),
  ("⁻", { replacement: "-", kind: UnicodeSuperscript }),
  ("⁼", { replacement: "=", kind: UnicodeSuperscript }),
  ("⁽", { replacement: "(", kind: UnicodeSuperscript }),
  ("⁾", { replacement: ")", kind: UnicodeSuperscript }),
  ("⁰", { replacement: "0", kind: UnicodeSuperscript }),
  ("¹", { replacement: "1", kind: UnicodeSuperscript }),
  ("²", { replacement: "2", kind: UnicodeSuperscript }),
  ("³", { replacement: "3", kind: UnicodeSuperscript }),
  ("⁴", { replacement: "4", kind: UnicodeSuperscript }),
  ("⁵", { replacement: "5", kind: UnicodeSuperscript }),
  ("⁶", { replacement: "6", kind: UnicodeSuperscript }),
  ("⁷", { replacement: "7", kind: UnicodeSuperscript }),
  ("⁸", { replacement: "8", kind: UnicodeSuperscript }),
  ("⁹", { replacement: "9", kind: UnicodeSuperscript }),
  ("ᴬ", { replacement: "A", kind: UnicodeSuperscript }),
  ("ᴮ", { replacement: "B", kind: UnicodeSuperscript }),
  ("ᴰ", { replacement: "D", kind: UnicodeSuperscript }),
  ("ᴱ", { replacement: "E", kind: UnicodeSuperscript }),
  ("ᴳ", { replacement: "G", kind: UnicodeSuperscript }),
  ("ᴴ", { replacement: "H", kind: UnicodeSuperscript }),
  ("ᴵ", { replacement: "I", kind: UnicodeSuperscript }),
  ("ᴶ", { replacement: "J", kind: UnicodeSuperscript }),
  ("ᴷ", { replacement: "K", kind: UnicodeSuperscript }),
  ("ᴸ", { replacement: "L", kind: UnicodeSuperscript }),
  ("ᴹ", { replacement: "M", kind: UnicodeSuperscript }),
  ("ᴺ", { replacement: "N", kind: UnicodeSuperscript }),
  ("ᴼ", { replacement: "O", kind: UnicodeSuperscript }),
  ("ᴾ", { replacement: "P", kind: UnicodeSuperscript }),
  ("ᴿ", { replacement: "R", kind: UnicodeSuperscript }),
  ("ᵀ", { replacement: "T", kind: UnicodeSuperscript }),
  ("ᵁ", { replacement: "U", kind: UnicodeSuperscript }),
  ("ⱽ", { replacement: "V", kind: UnicodeSuperscript }),
  ("ᵂ", { replacement: "W", kind: UnicodeSuperscript }),
  ("ᵃ", { replacement: "a", kind: UnicodeSuperscript }),
  ("ᵇ", { replacement: "b", kind: UnicodeSuperscript }),
  ("ᶜ", { replacement: "c", kind: UnicodeSuperscript }),
  ("ᵈ", { replacement: "d", kind: UnicodeSuperscript }),
  ("ᵉ", { replacement: "e", kind: UnicodeSuperscript }),
  ("ᶠ", { replacement: "f", kind: UnicodeSuperscript }),
  ("ᵍ", { replacement: "g", kind: UnicodeSuperscript }),
  ("ʰ", { replacement: "h", kind: UnicodeSuperscript }),
  ("ⁱ", { replacement: "i", kind: UnicodeSuperscript }),
  ("ʲ", { replacement: "j", kind: UnicodeSuperscript }),
  ("ᵏ", { replacement: "k", kind: UnicodeSuperscript }),
  ("ˡ", { replacement: "l", kind: UnicodeSuperscript }),
  ("ᵐ", { replacement: "m", kind: UnicodeSuperscript }),
  ("ⁿ", { replacement: "n", kind: UnicodeSuperscript }),
  ("ᵒ", { replacement: "o", kind: UnicodeSuperscript }),
  ("ᵖ", { replacement: "p", kind: UnicodeSuperscript }),
  ("ʳ", { replacement: "r", kind: UnicodeSuperscript }),
  ("ˢ", { replacement: "s", kind: UnicodeSuperscript }),
  ("ᵗ", { replacement: "t", kind: UnicodeSuperscript }),
  ("ᵘ", { replacement: "u", kind: UnicodeSuperscript }),
  ("ᵛ", { replacement: "v", kind: UnicodeSuperscript }),
  ("ʷ", { replacement: "w", kind: UnicodeSuperscript }),
  ("ˣ", { replacement: "x", kind: UnicodeSuperscript }),
  ("ʸ", { replacement: "y", kind: UnicodeSuperscript }),
  ("ᶻ", { replacement: "z", kind: UnicodeSuperscript }),
  ("ᵝ", { replacement: "β", kind: UnicodeSuperscript }),
  ("ᵞ", { replacement: "γ", kind: UnicodeSuperscript }),
  ("ᵟ", { replacement: "δ", kind: UnicodeSuperscript }),
  ("ᵠ", { replacement: "ϕ", kind: UnicodeSuperscript }),
  ("ᵡ", { replacement: "χ", kind: UnicodeSuperscript }),
  ("ᶿ", { replacement: "θ", kind: UnicodeSuperscript }),
])

///|
fn lookup_unicode_script(text : String) -> UnicodeScript? {
  unicode_scripts.get(text)
}

///|
/// Returns the Unicode superscript or subscript character for `replacement`.
///
/// The parser and renderers share `unicode_scripts` as the canonical table.
pub fn unicode_script_character(
  kind : UnicodeScriptKind,
  replacement : String,
) -> String? {
  for character, script in unicode_scripts {
    if script.kind == kind && script.replacement == replacement {
      return Some(character)
    }
  }
  None
}
