///|
/// Returns the Unicode mathematical alphanumeric character for a given font
/// style and ASCII letter/digit, or `None` when no mapping exists.
///
/// Font styles that match LaTeX commands:
/// - `mathbf` / `boldsymbol` — Bold / Bold Italic
/// - `mathit` — Italic
/// - `mathbb` — Double-struck (blackboard bold)
/// - `mathcal` — Calligraphic / Script
/// - `mathfrak` — Fraktur
/// - `mathscr` — Script (rsfs)
/// - `mathsf` — Sans-serif
/// - `mathtt` — Monospace
/// - `mathsfit` — Sans-serif Italic
/// - `mathrm` / `mathnormal` — Roman / Normal (identity mapping not handled here)
pub fn unicode_font_character(font : String, char : String) -> String? {
  if char.length() != 1 {
    return None
  }
  let c = char[0]
  let cp = match font {
    "mathbf" | "boldsymbol" => {
      let base = if font == "boldsymbol" { 0x1D468 } else { 0x1D400 }
      match c {
        'A'..='Z' => Some(base + c.to_int() - ('A' : Char).to_int())
        'a'..='z' => Some(base + 26 + c.to_int() - ('a' : Char).to_int())
        '0'..='9' if font != "boldsymbol" =>
          Some(0x1D7CE + c.to_int() - ('0' : Char).to_int())
        _ => None
      }
    }
    "mathit" | "mathnormal" =>
      match c {
        'A'..='Z' => Some(0x1D434 + c.to_int() - ('A' : Char).to_int())
        'a'..='z' => Some(0x1D44E + c.to_int() - ('a' : Char).to_int())
        _ => None
      }
    "mathsf" =>
      match c {
        'A'..='Z' => Some(0x1D5A0 + c.to_int() - ('A' : Char).to_int())
        'a'..='z' => Some(0x1D5BA + c.to_int() - ('a' : Char).to_int())
        '0'..='9' => Some(0x1D7E2 + c.to_int() - ('0' : Char).to_int())
        _ => None
      }
    "mathtt" =>
      match c {
        'A'..='Z' => Some(0x1D670 + c.to_int() - ('A' : Char).to_int())
        'a'..='z' => Some(0x1D68A + c.to_int() - ('a' : Char).to_int())
        '0'..='9' => Some(0x1D7F6 + c.to_int() - ('0' : Char).to_int())
        _ => None
      }
    "mathbb" =>
      match c {
        'A' => Some(0x1D538)
        'B' => Some(0x1D539)
        'C' => Some(0x2102)
        'D' => Some(0x1D53B)
        'E' => Some(0x1D53C)
        'F' => Some(0x1D53D)
        'G' => Some(0x1D53E)
        'H' => Some(0x210D)
        'I' => Some(0x1D540)
        'J' => Some(0x1D541)
        'K' => Some(0x1D542)
        'L' => Some(0x1D543)
        'M' => Some(0x1D544)
        'N' => Some(0x2115)
        'O' => Some(0x1D546)
        'P' => Some(0x2119)
        'Q' => Some(0x211A)
        'R' => Some(0x211D)
        'S' => Some(0x1D54A)
        'T' => Some(0x1D54B)
        'U' => Some(0x1D54C)
        'V' => Some(0x1D54D)
        'W' => Some(0x1D54E)
        'X' => Some(0x1D54F)
        'Y' => Some(0x1D550)
        'Z' => Some(0x2124)
        'a'..='z' => Some(0x1D552 + c.to_int() - ('a' : Char).to_int())
        _ => None
      }
    "mathcal" =>
      match c {
        'A' => Some(0x1D49C)
        'B' => Some(0x212C)
        'C' => Some(0x1D49E)
        'D' => Some(0x1D49F)
        'E' => Some(0x2130)
        'F' => Some(0x2131)
        'G' => Some(0x1D4A2)
        'H' => Some(0x210B)
        'I' => Some(0x2110)
        'J' => Some(0x1D4A5)
        'K' => Some(0x1D4A6)
        'L' => Some(0x2112)
        'M' => Some(0x2133)
        'N' => Some(0x1D4A9)
        'O' => Some(0x1D4AA)
        'P' => Some(0x1D4AB)
        'Q' => Some(0x1D4AC)
        'R' => Some(0x211B)
        'S' => Some(0x1D4AE)
        'T' => Some(0x1D4AF)
        'U' => Some(0x1D4B0)
        'V' => Some(0x1D4B1)
        'W' => Some(0x1D4B2)
        'X' => Some(0x1D4B3)
        'Y' => Some(0x1D4B4)
        'Z' => Some(0x1D4B5)
        _ => None
      }
    "mathfrak" =>
      match c {
        'A' => Some(0x1D504)
        'B' => Some(0x1D505)
        'C' => Some(0x212D)
        'D' => Some(0x1D507)
        'E' => Some(0x1D508)
        'F' => Some(0x1D509)
        'G' => Some(0x1D50A)
        'H' => Some(0x210C)
        'I' => Some(0x2111)
        'J' => Some(0x1D50D)
        'K' => Some(0x1D50E)
        'L' => Some(0x1D50F)
        'M' => Some(0x1D510)
        'N' => Some(0x1D511)
        'O' => Some(0x1D512)
        'P' => Some(0x1D513)
        'Q' => Some(0x1D514)
        'R' => Some(0x211C)
        'S' => Some(0x1D516)
        'T' => Some(0x1D517)
        'U' => Some(0x1D518)
        'V' => Some(0x1D519)
        'W' => Some(0x1D51A)
        'X' => Some(0x1D51B)
        'Y' => Some(0x1D51C)
        'Z' => Some(0x2128)
        'a'..='z' => Some(0x1D51E + c.to_int() - ('a' : Char).to_int())
        _ => None
      }
    "mathscr" =>
      match c {
        'A'..='Z' => Some(0x1D4D0 + c.to_int() - ('A' : Char).to_int())
        'a'..='z' => Some(0x1D4EA + c.to_int() - ('a' : Char).to_int())
        _ => None
      }
    "mathsfit" =>
      match c {
        'A'..='Z' => Some(0x1D608 + c.to_int() - ('A' : Char).to_int())
        'a'..='z' => Some(0x1D622 + c.to_int() - ('a' : Char).to_int())
        _ => None
      }
    _ => None
  }
  match cp {
    Some(cp) => Some(String::from_array([Int::unsafe_to_char(cp)]))
    None => None
  }
}
