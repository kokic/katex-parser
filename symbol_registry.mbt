///|
priv enum SymbolGroup {
  AccentTokenGroup
  BinaryGroup
  CloseGroup
  InnerGroup
  MathOrdGroup
  OperatorTokenGroup
  OpenGroup
  PunctuationGroup
  RelationGroup
  SpacingGroup
  TextOrdGroup
}

///|
priv struct SymbolSpec {
  group : SymbolGroup
}

///|
priv struct SymbolRegistry {
  math : Map[String, SymbolSpec]
  text : Map[String, SymbolSpec]
}

///|
fn SymbolRegistry::define_symbol(
  self : SymbolRegistry,
  mode : Mode,
  group : SymbolGroup,
  replacement : String,
  name : String,
  accept_unicode? : Bool = false,
) -> Unit {
  let table = if mode == Math { self.math } else { self.text }
  let spec = { group, }
  table[name] = spec
  if accept_unicode && replacement != "" {
    table[replacement] = spec
  }
}

///|
fn codepoint_string(codepoint : Int) -> String {
  String::from_array([codepoint.to_char().unwrap()])
}

///|
fn build_builtin_symbols() -> SymbolRegistry {
  let registry : SymbolRegistry = { math: Map([]), text: Map([]) }
  registry.define_symbol(
    Math,
    RelationGroup,
    "≡",
    "\\equiv",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≺",
    "\\prec",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≻",
    "\\succ",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "∼",
    "\\sim",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⊥", "\\perp")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪯",
    "\\preceq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪰",
    "\\succeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≃",
    "\\simeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "∣",
    "\\mid",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≪",
    "\\ll",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≫",
    "\\gg",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≍",
    "\\asymp",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "∥", "\\parallel")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋈",
    "\\bowtie",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⌣",
    "\\smile",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊑",
    "\\sqsubseteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊒",
    "\\sqsupseteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≐",
    "\\doteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⌢",
    "\\frown",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "∋",
    "\\ni",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "∝",
    "\\propto",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊢",
    "\\vdash",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊣",
    "\\dashv",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "∋", "\\owns")
  registry.define_symbol(Math, PunctuationGroup, ".", "\\ldotp")
  registry.define_symbol(Math, PunctuationGroup, "⋅", "\\cdotp")
  registry.define_symbol(Math, PunctuationGroup, "⋅", "·")
  registry.define_symbol(Text, TextOrdGroup, "⋅", "·")
  registry.define_symbol(Math, TextOrdGroup, "#", "\\#")
  registry.define_symbol(Text, TextOrdGroup, "#", "\\#")
  registry.define_symbol(Math, TextOrdGroup, "&", "\\&")
  registry.define_symbol(Text, TextOrdGroup, "&", "\\&")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "ℵ",
    "\\aleph",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∀",
    "\\forall",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "ℏ",
    "\\hbar",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∃",
    "\\exists",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∇",
    "\\nabla",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "♭",
    "\\flat",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "ℓ",
    "\\ell",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "♮",
    "\\natural",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "♣",
    "\\clubsuit",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "℘", "\\wp", accept_unicode=true)
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "♯",
    "\\sharp",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "♢",
    "\\diamondsuit",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "ℜ", "\\Re", accept_unicode=true)
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "♡",
    "\\heartsuit",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "ℑ", "\\Im", accept_unicode=true)
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "♠",
    "\\spadesuit",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "§", "\\S", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "§", "\\S")
  registry.define_symbol(Math, TextOrdGroup, "¶", "\\P", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "¶", "\\P")
  registry.define_symbol(Math, TextOrdGroup, "†", "\\dag")
  registry.define_symbol(Text, TextOrdGroup, "†", "\\dag")
  registry.define_symbol(Text, TextOrdGroup, "†", "\\textdagger")
  registry.define_symbol(Math, TextOrdGroup, "‡", "\\ddag")
  registry.define_symbol(Text, TextOrdGroup, "‡", "\\ddag")
  registry.define_symbol(Text, TextOrdGroup, "‡", "\\textdaggerdbl")
  registry.define_symbol(
    Math,
    CloseGroup,
    "⎱",
    "\\rmoustache",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    OpenGroup,
    "⎰",
    "\\lmoustache",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    CloseGroup,
    "⟯",
    "\\rgroup",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    OpenGroup,
    "⟮",
    "\\lgroup",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "∓", "\\mp", accept_unicode=true)
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊖",
    "\\ominus",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊎",
    "\\uplus",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊓",
    "\\sqcap",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "∗", "\\ast")
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊔",
    "\\sqcup",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "◯",
    "\\bigcirc",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "∙",
    "\\bullet",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "‡", "\\ddagger")
  registry.define_symbol(Math, BinaryGroup, "≀", "\\wr", accept_unicode=true)
  registry.define_symbol(Math, BinaryGroup, "⨿", "\\amalg")
  registry.define_symbol(Math, BinaryGroup, "&", "\\And")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⟵",
    "\\longleftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇐",
    "\\Leftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⟸",
    "\\Longleftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⟶",
    "\\longrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇒",
    "\\Rightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⟹",
    "\\Longrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↔",
    "\\leftrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⟷",
    "\\longleftrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇔",
    "\\Leftrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⟺",
    "\\Longleftrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↦",
    "\\mapsto",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⟼",
    "\\longmapsto",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↗",
    "\\nearrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↩",
    "\\hookleftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↪",
    "\\hookrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↘",
    "\\searrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↼",
    "\\leftharpoonup",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇀",
    "\\rightharpoonup",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↙",
    "\\swarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↽",
    "\\leftharpoondown",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇁",
    "\\rightharpoondown",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↖",
    "\\nwarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇌",
    "\\rightleftharpoons",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≮",
    "\\nless",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@nleqslant")
  registry.define_symbol(Math, RelationGroup, "", "\\@nleqq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪇",
    "\\lneq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≨",
    "\\lneqq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@lvertneqq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋦",
    "\\lnsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪉",
    "\\lnapprox",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊀",
    "\\nprec",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋠",
    "\\npreceq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋨",
    "\\precnsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪹",
    "\\precnapprox",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≁",
    "\\nsim",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@nshortmid")
  registry.define_symbol(
    Math,
    RelationGroup,
    "∤",
    "\\nmid",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊬",
    "\\nvdash",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊭",
    "\\nvDash",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⋪", "\\ntriangleleft")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋬",
    "\\ntrianglelefteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊊",
    "\\subsetneq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@varsubsetneq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⫋",
    "\\subsetneqq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@varsubsetneqq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≯",
    "\\ngtr",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@ngeqslant")
  registry.define_symbol(Math, RelationGroup, "", "\\@ngeqq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪈",
    "\\gneq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≩",
    "\\gneqq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@gvertneqq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋧",
    "\\gnsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪊",
    "\\gnapprox",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊁",
    "\\nsucc",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋡",
    "\\nsucceq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋩",
    "\\succnsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪺",
    "\\succnapprox",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≆",
    "\\ncong",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@nshortparallel")
  registry.define_symbol(
    Math,
    RelationGroup,
    "∦",
    "\\nparallel",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊯",
    "\\nVDash",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⋫", "\\ntriangleright")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋭",
    "\\ntrianglerighteq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@nsupseteqq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊋",
    "\\supsetneq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@varsupsetneq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⫌",
    "\\supsetneqq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@varsupsetneqq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊮",
    "\\nVdash",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪵",
    "\\precneqq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪶",
    "\\succneqq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@nsubseteqq")
  registry.define_symbol(Math, BinaryGroup, "⊴", "\\unlhd")
  registry.define_symbol(Math, BinaryGroup, "⊵", "\\unrhd")
  registry.define_symbol(
    Math,
    RelationGroup,
    "↚",
    "\\nleftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↛",
    "\\nrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇍",
    "\\nLeftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇏",
    "\\nRightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↮",
    "\\nleftrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇎",
    "\\nLeftrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "△", "\\vartriangle")
  registry.define_symbol(Math, TextOrdGroup, "ℏ", "\\hslash")
  registry.define_symbol(Math, TextOrdGroup, "▽", "\\triangledown")
  registry.define_symbol(Math, TextOrdGroup, "◊", "\\lozenge")
  registry.define_symbol(Math, TextOrdGroup, "Ⓢ", "\\circledS")
  registry.define_symbol(Math, TextOrdGroup, "®", "\\circledR")
  registry.define_symbol(Text, TextOrdGroup, "®", "\\circledR")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∡",
    "\\measuredangle",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "∄", "\\nexists")
  registry.define_symbol(Math, TextOrdGroup, "℧", "\\mho")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Ⅎ",
    "\\Finv",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "⅁",
    "\\Game",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "‵", "\\backprime")
  registry.define_symbol(Math, TextOrdGroup, "▲", "\\blacktriangle")
  registry.define_symbol(Math, TextOrdGroup, "▼", "\\blacktriangledown")
  registry.define_symbol(Math, TextOrdGroup, "■", "\\blacksquare")
  registry.define_symbol(Math, TextOrdGroup, "⧫", "\\blacklozenge")
  registry.define_symbol(Math, TextOrdGroup, "★", "\\bigstar")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∢",
    "\\sphericalangle",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∁",
    "\\complement",
    accept_unicode=true,
  )
  registry.define_symbol(Text, TextOrdGroup, "ð", "ð")
  registry.define_symbol(Math, TextOrdGroup, "╱", "\\diagup")
  registry.define_symbol(Math, TextOrdGroup, "╲", "\\diagdown")
  registry.define_symbol(Math, TextOrdGroup, "□", "\\square")
  registry.define_symbol(Math, TextOrdGroup, "□", "\\Box")
  registry.define_symbol(Math, TextOrdGroup, "◊", "\\Diamond")
  registry.define_symbol(Text, TextOrdGroup, "¥", "\\yen", accept_unicode=true)
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "✓",
    "\\checkmark",
    accept_unicode=true,
  )
  registry.define_symbol(Text, TextOrdGroup, "✓", "\\checkmark")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "ℶ",
    "\\beth",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "ℸ",
    "\\daleth",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "ℷ",
    "\\gimel",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "ϝ",
    "\\digamma",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "ϰ", "\\varkappa")
  registry.define_symbol(
    Math,
    OpenGroup,
    "┌",
    "\\@ulcorner",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    CloseGroup,
    "┐",
    "\\@urcorner",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    OpenGroup,
    "└",
    "\\@llcorner",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    CloseGroup,
    "┘",
    "\\@lrcorner",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≦",
    "\\leqq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⩽",
    "\\leqslant",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪕",
    "\\eqslantless",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≲",
    "\\lesssim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪅",
    "\\lessapprox",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≊",
    "\\approxeq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "⋖", "\\lessdot")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋘",
    "\\lll",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≶",
    "\\lessgtr",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋚",
    "\\lesseqgtr",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪋",
    "\\lesseqqgtr",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "≑", "\\doteqdot")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≓",
    "\\risingdotseq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≒",
    "\\fallingdotseq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "∽",
    "\\backsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋍",
    "\\backsimeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⫅",
    "\\subseteqq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋐",
    "\\Subset",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊏",
    "\\sqsubset",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≼",
    "\\preccurlyeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋞",
    "\\curlyeqprec",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≾",
    "\\precsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪷",
    "\\precapprox",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⊲", "\\vartriangleleft")
  registry.define_symbol(Math, RelationGroup, "⊴", "\\trianglelefteq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊨",
    "\\vDash",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊪",
    "\\Vvdash",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⌣", "\\smallsmile")
  registry.define_symbol(Math, RelationGroup, "⌢", "\\smallfrown")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≏",
    "\\bumpeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≎",
    "\\Bumpeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≧",
    "\\geqq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⩾",
    "\\geqslant",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪖",
    "\\eqslantgtr",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≳",
    "\\gtrsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪆",
    "\\gtrapprox",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "⋗", "\\gtrdot")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋙",
    "\\ggg",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≷",
    "\\gtrless",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋛",
    "\\gtreqless",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪌",
    "\\gtreqqless",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≖",
    "\\eqcirc",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≗",
    "\\circeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≜",
    "\\triangleq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "∼", "\\thicksim")
  registry.define_symbol(Math, RelationGroup, "≈", "\\thickapprox")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⫆",
    "\\supseteqq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋑",
    "\\Supset",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊐",
    "\\sqsupset",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≽",
    "\\succcurlyeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋟",
    "\\curlyeqsucc",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≿",
    "\\succsim",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⪸",
    "\\succapprox",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⊳", "\\vartriangleright")
  registry.define_symbol(Math, RelationGroup, "⊵", "\\trianglerighteq")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊩",
    "\\Vdash",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "∣", "\\shortmid")
  registry.define_symbol(Math, RelationGroup, "∥", "\\shortparallel")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≬",
    "\\between",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⋔",
    "\\pitchfork",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "∝", "\\varpropto")
  registry.define_symbol(Math, RelationGroup, "◀", "\\blacktriangleleft")
  registry.define_symbol(
    Math,
    RelationGroup,
    "∴",
    "\\therefore",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "∍", "\\backepsilon")
  registry.define_symbol(Math, RelationGroup, "▶", "\\blacktriangleright")
  registry.define_symbol(
    Math,
    RelationGroup,
    "∵",
    "\\because",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⋘", "\\llless")
  registry.define_symbol(Math, RelationGroup, "⋙", "\\gggtr")
  registry.define_symbol(Math, BinaryGroup, "⊲", "\\lhd")
  registry.define_symbol(Math, BinaryGroup, "⊳", "\\rhd")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≂",
    "\\eqsim",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⋈", "\\Join")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≑",
    "\\Doteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "∔",
    "\\dotplus",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "∖", "\\smallsetminus")
  registry.define_symbol(Math, BinaryGroup, "⋒", "\\Cap", accept_unicode=true)
  registry.define_symbol(Math, BinaryGroup, "⋓", "\\Cup", accept_unicode=true)
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⩞",
    "\\doublebarwedge",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊟",
    "\\boxminus",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊞",
    "\\boxplus",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋇",
    "\\divideontimes",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋉",
    "\\ltimes",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋊",
    "\\rtimes",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋋",
    "\\leftthreetimes",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋌",
    "\\rightthreetimes",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋏",
    "\\curlywedge",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋎",
    "\\curlyvee",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊝",
    "\\circleddash",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊛",
    "\\circledast",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "⋅", "\\centerdot")
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊺",
    "\\intercal",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "⋒", "\\doublecap")
  registry.define_symbol(Math, BinaryGroup, "⋓", "\\doublecup")
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊠",
    "\\boxtimes",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇢",
    "\\dashrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇠",
    "\\dashleftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇇",
    "\\leftleftarrows",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇆",
    "\\leftrightarrows",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇚",
    "\\Lleftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↞",
    "\\twoheadleftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↢",
    "\\leftarrowtail",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↫",
    "\\looparrowleft",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇋",
    "\\leftrightharpoons",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↶",
    "\\curvearrowleft",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↺",
    "\\circlearrowleft",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↰",
    "\\Lsh",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇈",
    "\\upuparrows",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↿",
    "\\upharpoonleft",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇃",
    "\\downharpoonleft",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊶",
    "\\origof",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊷",
    "\\imageof",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊸",
    "\\multimap",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↭",
    "\\leftrightsquigarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇉",
    "\\rightrightarrows",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇄",
    "\\rightleftarrows",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↠",
    "\\twoheadrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↣",
    "\\rightarrowtail",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↬",
    "\\looparrowright",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↷",
    "\\curvearrowright",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↻",
    "\\circlearrowright",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↱",
    "\\Rsh",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇊",
    "\\downdownarrows",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↾",
    "\\upharpoonright",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇂",
    "\\downharpoonright",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇝",
    "\\rightsquigarrow",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⇝", "\\leadsto")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇛",
    "\\Rrightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "↾", "\\restriction")
  registry.define_symbol(Math, TextOrdGroup, "‘", "`")
  registry.define_symbol(Math, TextOrdGroup, "$", "\\$")
  registry.define_symbol(Text, TextOrdGroup, "$", "\\$")
  registry.define_symbol(Text, TextOrdGroup, "$", "\\textdollar")
  registry.define_symbol(Math, TextOrdGroup, "%", "\\%")
  registry.define_symbol(Text, TextOrdGroup, "%", "\\%")
  registry.define_symbol(Math, TextOrdGroup, "_", "\\_")
  registry.define_symbol(Text, TextOrdGroup, "_", "\\_")
  registry.define_symbol(Text, TextOrdGroup, "_", "\\textunderscore")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∠",
    "\\angle",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∞",
    "\\infty",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "′", "\\prime")
  registry.define_symbol(Math, TextOrdGroup, "△", "\\triangle")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Γ",
    "\\Gamma",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Δ",
    "\\Delta",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Θ",
    "\\Theta",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Λ",
    "\\Lambda",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "Ξ", "\\Xi", accept_unicode=true)
  registry.define_symbol(Math, TextOrdGroup, "Π", "\\Pi", accept_unicode=true)
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Σ",
    "\\Sigma",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Υ",
    "\\Upsilon",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "Φ", "\\Phi", accept_unicode=true)
  registry.define_symbol(Math, TextOrdGroup, "Ψ", "\\Psi", accept_unicode=true)
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "Ω",
    "\\Omega",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "A", "Α")
  registry.define_symbol(Math, TextOrdGroup, "B", "Β")
  registry.define_symbol(Math, TextOrdGroup, "E", "Ε")
  registry.define_symbol(Math, TextOrdGroup, "Z", "Ζ")
  registry.define_symbol(Math, TextOrdGroup, "H", "Η")
  registry.define_symbol(Math, TextOrdGroup, "I", "Ι")
  registry.define_symbol(Math, TextOrdGroup, "K", "Κ")
  registry.define_symbol(Math, TextOrdGroup, "M", "Μ")
  registry.define_symbol(Math, TextOrdGroup, "N", "Ν")
  registry.define_symbol(Math, TextOrdGroup, "O", "Ο")
  registry.define_symbol(Math, TextOrdGroup, "P", "Ρ")
  registry.define_symbol(Math, TextOrdGroup, "T", "Τ")
  registry.define_symbol(Math, TextOrdGroup, "X", "Χ")
  registry.define_symbol(Math, TextOrdGroup, "¬", "\\neg", accept_unicode=true)
  registry.define_symbol(Math, TextOrdGroup, "¬", "\\lnot")
  registry.define_symbol(Math, TextOrdGroup, "⊤", "\\top")
  registry.define_symbol(Math, TextOrdGroup, "⊥", "\\bot")
  registry.define_symbol(Math, TextOrdGroup, "∅", "\\emptyset")
  registry.define_symbol(Math, TextOrdGroup, "∅", "\\varnothing")
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "α",
    "\\alpha",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "β",
    "\\beta",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "γ",
    "\\gamma",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "δ",
    "\\delta",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ϵ",
    "\\epsilon",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ζ",
    "\\zeta",
    accept_unicode=true,
  )
  registry.define_symbol(Math, MathOrdGroup, "η", "\\eta", accept_unicode=true)
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "θ",
    "\\theta",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ι",
    "\\iota",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "κ",
    "\\kappa",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "λ",
    "\\lambda",
    accept_unicode=true,
  )
  registry.define_symbol(Math, MathOrdGroup, "μ", "\\mu", accept_unicode=true)
  registry.define_symbol(Math, MathOrdGroup, "ν", "\\nu", accept_unicode=true)
  registry.define_symbol(Math, MathOrdGroup, "ξ", "\\xi", accept_unicode=true)
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ο",
    "\\omicron",
    accept_unicode=true,
  )
  registry.define_symbol(Math, MathOrdGroup, "π", "\\pi", accept_unicode=true)
  registry.define_symbol(Math, MathOrdGroup, "ρ", "\\rho", accept_unicode=true)
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "σ",
    "\\sigma",
    accept_unicode=true,
  )
  registry.define_symbol(Math, MathOrdGroup, "τ", "\\tau", accept_unicode=true)
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "υ",
    "\\upsilon",
    accept_unicode=true,
  )
  registry.define_symbol(Math, MathOrdGroup, "ϕ", "\\phi", accept_unicode=true)
  registry.define_symbol(Math, MathOrdGroup, "χ", "\\chi", accept_unicode=true)
  registry.define_symbol(Math, MathOrdGroup, "ψ", "\\psi", accept_unicode=true)
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ω",
    "\\omega",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ε",
    "\\varepsilon",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ϑ",
    "\\vartheta",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ϖ",
    "\\varpi",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ϱ",
    "\\varrho",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "ς",
    "\\varsigma",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    MathOrdGroup,
    "φ",
    "\\varphi",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "∗", "*", accept_unicode=true)
  registry.define_symbol(Math, BinaryGroup, "+", "+")
  registry.define_symbol(Math, BinaryGroup, "−", "-", accept_unicode=true)
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⋅",
    "\\cdot",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "∘",
    "\\circ",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "÷", "\\div", accept_unicode=true)
  registry.define_symbol(Math, BinaryGroup, "±", "\\pm", accept_unicode=true)
  registry.define_symbol(
    Math,
    BinaryGroup,
    "×",
    "\\times",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "∩", "\\cap", accept_unicode=true)
  registry.define_symbol(Math, BinaryGroup, "∪", "\\cup", accept_unicode=true)
  registry.define_symbol(
    Math,
    BinaryGroup,
    "∖",
    "\\setminus",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "∧", "\\land")
  registry.define_symbol(Math, BinaryGroup, "∨", "\\lor")
  registry.define_symbol(
    Math,
    BinaryGroup,
    "∧",
    "\\wedge",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "∨", "\\vee", accept_unicode=true)
  registry.define_symbol(Math, TextOrdGroup, "√", "\\surd")
  registry.define_symbol(
    Math,
    OpenGroup,
    "⟨",
    "\\langle",
    accept_unicode=true,
  )
  registry.define_symbol(Math, OpenGroup, "∣", "\\lvert")
  registry.define_symbol(Math, OpenGroup, "∥", "\\lVert")
  registry.define_symbol(Math, CloseGroup, "?", "?")
  registry.define_symbol(Math, CloseGroup, "!", "!")
  registry.define_symbol(
    Math,
    CloseGroup,
    "⟩",
    "\\rangle",
    accept_unicode=true,
  )
  registry.define_symbol(Math, CloseGroup, "∣", "\\rvert")
  registry.define_symbol(Math, CloseGroup, "∥", "\\rVert")
  registry.define_symbol(Math, RelationGroup, "=", "=")
  registry.define_symbol(Math, RelationGroup, ":", ":")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≈",
    "\\approx",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≅",
    "\\cong",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "≥", "\\ge")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≥",
    "\\geq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "←", "\\gets")
  registry.define_symbol(Math, RelationGroup, ">", "\\gt", accept_unicode=true)
  registry.define_symbol(
    Math,
    RelationGroup,
    "∈",
    "\\in",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "", "\\@not")
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊂",
    "\\subset",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊃",
    "\\supset",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊆",
    "\\subseteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊇",
    "\\supseteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊈",
    "\\nsubseteq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⊉",
    "\\nsupseteq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "⊨", "\\models")
  registry.define_symbol(
    Math,
    RelationGroup,
    "←",
    "\\leftarrow",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "≤", "\\le")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≤",
    "\\leq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "<", "\\lt", accept_unicode=true)
  registry.define_symbol(
    Math,
    RelationGroup,
    "→",
    "\\rightarrow",
    accept_unicode=true,
  )
  registry.define_symbol(Math, RelationGroup, "→", "\\to")
  registry.define_symbol(
    Math,
    RelationGroup,
    "≱",
    "\\ngeq",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "≰",
    "\\nleq",
    accept_unicode=true,
  )
  registry.define_symbol(Math, SpacingGroup, " ", "\\ ")
  registry.define_symbol(Math, SpacingGroup, " ", "\\space")
  registry.define_symbol(Math, SpacingGroup, " ", "\\nobreakspace")
  registry.define_symbol(Text, SpacingGroup, " ", "\\ ")
  registry.define_symbol(Text, SpacingGroup, " ", " ")
  registry.define_symbol(Text, SpacingGroup, " ", "\\space")
  registry.define_symbol(Text, SpacingGroup, " ", "\\nobreakspace")
  registry.define_symbol(Math, SpacingGroup, "", "\\nobreak")
  registry.define_symbol(Math, SpacingGroup, "", "\\allowbreak")
  registry.define_symbol(Math, PunctuationGroup, ",", ",")
  registry.define_symbol(Math, PunctuationGroup, ";", ";")
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊼",
    "\\barwedge",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊻",
    "\\veebar",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊙",
    "\\odot",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊕",
    "\\oplus",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊗",
    "\\otimes",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "∂",
    "\\partial",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊘",
    "\\oslash",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊚",
    "\\circledcirc",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    BinaryGroup,
    "⊡",
    "\\boxdot",
    accept_unicode=true,
  )
  registry.define_symbol(Math, BinaryGroup, "△", "\\bigtriangleup")
  registry.define_symbol(Math, BinaryGroup, "▽", "\\bigtriangledown")
  registry.define_symbol(Math, BinaryGroup, "†", "\\dagger")
  registry.define_symbol(Math, BinaryGroup, "⋄", "\\diamond")
  registry.define_symbol(Math, BinaryGroup, "⋆", "\\star")
  registry.define_symbol(Math, BinaryGroup, "◃", "\\triangleleft")
  registry.define_symbol(Math, BinaryGroup, "▹", "\\triangleright")
  registry.define_symbol(Math, OpenGroup, "{", "\\{")
  registry.define_symbol(Text, TextOrdGroup, "{", "\\{")
  registry.define_symbol(Text, TextOrdGroup, "{", "\\textbraceleft")
  registry.define_symbol(Math, CloseGroup, "}", "\\}")
  registry.define_symbol(Text, TextOrdGroup, "}", "\\}")
  registry.define_symbol(Text, TextOrdGroup, "}", "\\textbraceright")
  registry.define_symbol(Math, OpenGroup, "{", "\\lbrace")
  registry.define_symbol(Math, CloseGroup, "}", "\\rbrace")
  registry.define_symbol(Math, OpenGroup, "[", "\\lbrack", accept_unicode=true)
  registry.define_symbol(
    Text,
    TextOrdGroup,
    "[",
    "\\lbrack",
    accept_unicode=true,
  )
  registry.define_symbol(Math, CloseGroup, "]", "\\rbrack", accept_unicode=true)
  registry.define_symbol(
    Text,
    TextOrdGroup,
    "]",
    "\\rbrack",
    accept_unicode=true,
  )
  registry.define_symbol(Math, OpenGroup, "(", "\\lparen", accept_unicode=true)
  registry.define_symbol(Math, CloseGroup, ")", "\\rparen", accept_unicode=true)
  registry.define_symbol(
    Text,
    TextOrdGroup,
    "<",
    "\\textless",
    accept_unicode=true,
  )
  registry.define_symbol(
    Text,
    TextOrdGroup,
    ">",
    "\\textgreater",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    OpenGroup,
    "⌊",
    "\\lfloor",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    CloseGroup,
    "⌋",
    "\\rfloor",
    accept_unicode=true,
  )
  registry.define_symbol(Math, OpenGroup, "⌈", "\\lceil", accept_unicode=true)
  registry.define_symbol(
    Math,
    CloseGroup,
    "⌉",
    "\\rceil",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "\\", "\\backslash")
  registry.define_symbol(Math, TextOrdGroup, "∣", "|")
  registry.define_symbol(Math, TextOrdGroup, "∣", "\\vert")
  registry.define_symbol(
    Text,
    TextOrdGroup,
    "|",
    "\\textbar",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "∥", "\\|")
  registry.define_symbol(Math, TextOrdGroup, "∥", "\\Vert")
  registry.define_symbol(Text, TextOrdGroup, "∥", "\\textbardbl")
  registry.define_symbol(Text, TextOrdGroup, "~", "\\textasciitilde")
  registry.define_symbol(Text, TextOrdGroup, "\\", "\\textbackslash")
  registry.define_symbol(Text, TextOrdGroup, "^", "\\textasciicircum")
  registry.define_symbol(
    Math,
    RelationGroup,
    "↑",
    "\\uparrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇑",
    "\\Uparrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↓",
    "\\downarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇓",
    "\\Downarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "↕",
    "\\updownarrow",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    RelationGroup,
    "⇕",
    "\\Updownarrow",
    accept_unicode=true,
  )
  registry.define_symbol(Math, OperatorTokenGroup, "∐", "\\coprod")
  registry.define_symbol(Math, OperatorTokenGroup, "⋁", "\\bigvee")
  registry.define_symbol(Math, OperatorTokenGroup, "⋀", "\\bigwedge")
  registry.define_symbol(Math, OperatorTokenGroup, "⨄", "\\biguplus")
  registry.define_symbol(Math, OperatorTokenGroup, "⋂", "\\bigcap")
  registry.define_symbol(Math, OperatorTokenGroup, "⋃", "\\bigcup")
  registry.define_symbol(Math, OperatorTokenGroup, "∫", "\\int")
  registry.define_symbol(Math, OperatorTokenGroup, "∫", "\\intop")
  registry.define_symbol(Math, OperatorTokenGroup, "∬", "\\iint")
  registry.define_symbol(Math, OperatorTokenGroup, "∭", "\\iiint")
  registry.define_symbol(Math, OperatorTokenGroup, "∏", "\\prod")
  registry.define_symbol(Math, OperatorTokenGroup, "∑", "\\sum")
  registry.define_symbol(Math, OperatorTokenGroup, "⨂", "\\bigotimes")
  registry.define_symbol(Math, OperatorTokenGroup, "⨁", "\\bigoplus")
  registry.define_symbol(Math, OperatorTokenGroup, "⨀", "\\bigodot")
  registry.define_symbol(Math, OperatorTokenGroup, "∮", "\\oint")
  registry.define_symbol(Math, OperatorTokenGroup, "∯", "\\oiint")
  registry.define_symbol(Math, OperatorTokenGroup, "∰", "\\oiiint")
  registry.define_symbol(Math, OperatorTokenGroup, "⨆", "\\bigsqcup")
  registry.define_symbol(Math, OperatorTokenGroup, "∫", "\\smallint")
  registry.define_symbol(Text, InnerGroup, "…", "\\textellipsis")
  registry.define_symbol(Math, InnerGroup, "…", "\\mathellipsis")
  registry.define_symbol(
    Text,
    InnerGroup,
    "…",
    "\\ldots",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    InnerGroup,
    "…",
    "\\ldots",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    InnerGroup,
    "⋯",
    "\\@cdots",
    accept_unicode=true,
  )
  registry.define_symbol(
    Math,
    InnerGroup,
    "⋱",
    "\\ddots",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "⋮", "\\varvdots")
  registry.define_symbol(Text, TextOrdGroup, "⋮", "\\varvdots")
  registry.define_symbol(Math, AccentTokenGroup, "ˊ", "\\acute")
  registry.define_symbol(Math, AccentTokenGroup, "ˋ", "\\grave")
  registry.define_symbol(Math, AccentTokenGroup, "¨", "\\ddot")
  registry.define_symbol(Math, AccentTokenGroup, "~", "\\tilde")
  registry.define_symbol(Math, AccentTokenGroup, "ˉ", "\\bar")
  registry.define_symbol(Math, AccentTokenGroup, "˘", "\\breve")
  registry.define_symbol(Math, AccentTokenGroup, "ˇ", "\\check")
  registry.define_symbol(Math, AccentTokenGroup, "^", "\\hat")
  registry.define_symbol(Math, AccentTokenGroup, "⃗", "\\vec")
  registry.define_symbol(Math, AccentTokenGroup, "˙", "\\dot")
  registry.define_symbol(Math, AccentTokenGroup, "˚", "\\mathring")
  registry.define_symbol(Math, MathOrdGroup, "", "\\@imath")
  registry.define_symbol(Math, MathOrdGroup, "", "\\@jmath")
  registry.define_symbol(Math, TextOrdGroup, "ı", "ı")
  registry.define_symbol(Math, TextOrdGroup, "ȷ", "ȷ")
  registry.define_symbol(Text, TextOrdGroup, "ı", "\\i", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "ȷ", "\\j", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "ß", "\\ss", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "æ", "\\ae", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "œ", "\\oe", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "ø", "\\o", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "Æ", "\\AE", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "Œ", "\\OE", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "Ø", "\\O", accept_unicode=true)
  registry.define_symbol(Text, AccentTokenGroup, "ˊ", "\\'")
  registry.define_symbol(Text, AccentTokenGroup, "ˋ", "\\`")
  registry.define_symbol(Text, AccentTokenGroup, "ˆ", "\\^")
  registry.define_symbol(Text, AccentTokenGroup, "˜", "\\~")
  registry.define_symbol(Text, AccentTokenGroup, "ˉ", "\\=")
  registry.define_symbol(Text, AccentTokenGroup, "˘", "\\u")
  registry.define_symbol(Text, AccentTokenGroup, "˙", "\\.")
  registry.define_symbol(Text, AccentTokenGroup, "¸", "\\c")
  registry.define_symbol(Text, AccentTokenGroup, "˚", "\\r")
  registry.define_symbol(Text, AccentTokenGroup, "ˇ", "\\v")
  registry.define_symbol(Text, AccentTokenGroup, "¨", "\\\"")
  registry.define_symbol(Text, AccentTokenGroup, "˝", "\\H")
  registry.define_symbol(Text, AccentTokenGroup, "◯", "\\textcircled")
  registry.define_symbol(Text, TextOrdGroup, "–", "--", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "–", "\\textendash")
  registry.define_symbol(Text, TextOrdGroup, "—", "---", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "—", "\\textemdash")
  registry.define_symbol(Text, TextOrdGroup, "‘", "`", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "‘", "\\textquoteleft")
  registry.define_symbol(Text, TextOrdGroup, "’", "'", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "’", "\\textquoteright")
  registry.define_symbol(Text, TextOrdGroup, "“", "``", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "“", "\\textquotedblleft")
  registry.define_symbol(Text, TextOrdGroup, "”", "''", accept_unicode=true)
  registry.define_symbol(Text, TextOrdGroup, "”", "\\textquotedblright")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "°",
    "\\degree",
    accept_unicode=true,
  )
  registry.define_symbol(Text, TextOrdGroup, "°", "\\degree")
  registry.define_symbol(
    Text,
    TextOrdGroup,
    "°",
    "\\textdegree",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "£", "\\pounds")
  registry.define_symbol(
    Math,
    TextOrdGroup,
    "£",
    "\\mathsterling",
    accept_unicode=true,
  )
  registry.define_symbol(Text, TextOrdGroup, "£", "\\pounds")
  registry.define_symbol(
    Text,
    TextOrdGroup,
    "£",
    "\\textsterling",
    accept_unicode=true,
  )
  registry.define_symbol(Math, TextOrdGroup, "✠", "\\maltese")
  registry.define_symbol(Text, TextOrdGroup, "✠", "\\maltese")
  registry.define_symbol(Math, TextOrdGroup, "C", "ℂ")
  registry.define_symbol(Text, TextOrdGroup, "C", "ℂ")
  registry.define_symbol(Math, TextOrdGroup, "H", "ℍ")
  registry.define_symbol(Text, TextOrdGroup, "H", "ℍ")
  registry.define_symbol(Math, TextOrdGroup, "N", "ℕ")
  registry.define_symbol(Text, TextOrdGroup, "N", "ℕ")
  registry.define_symbol(Math, TextOrdGroup, "P", "ℙ")
  registry.define_symbol(Text, TextOrdGroup, "P", "ℙ")
  registry.define_symbol(Math, TextOrdGroup, "Q", "ℚ")
  registry.define_symbol(Text, TextOrdGroup, "Q", "ℚ")
  registry.define_symbol(Math, TextOrdGroup, "R", "ℝ")
  registry.define_symbol(Text, TextOrdGroup, "R", "ℝ")
  registry.define_symbol(Math, TextOrdGroup, "Z", "ℤ")
  registry.define_symbol(Text, TextOrdGroup, "Z", "ℤ")
  registry.define_symbol(Math, MathOrdGroup, "h", "ℎ")
  registry.define_symbol(Text, MathOrdGroup, "h", "ℎ")
  registry.define_symbol(Math, TextOrdGroup, "ð", "\\eth", accept_unicode=true)
  registry.define_symbol(Math, TextOrdGroup, "¥", "\\yen", accept_unicode=true)
  for ch in "0123456789/@.\"" {
    let text = String::from_array([ch])
    registry.define_symbol(Math, TextOrdGroup, text, text)
  }
  for ch in "0123456789!@*()-=+\";:?/.," {
    let text = String::from_array([ch])
    registry.define_symbol(Text, TextOrdGroup, text, text)
  }
  let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  for index, ch in letters {
    let text = String::from_array([ch])
    registry.define_symbol(Math, MathOrdGroup, text, text)
    registry.define_symbol(Text, TextOrdGroup, text, text)
    for
      start in [
        0x1D400, 0x1D434, 0x1D468, 0x1D504, 0x1D56C, 0x1D5A0, 0x1D5D4, 0x1D608, 0x1D670,
      ] {
      let wide = codepoint_string(start + index)
      registry.define_symbol(Math, MathOrdGroup, text, wide)
      registry.define_symbol(Text, TextOrdGroup, text, wide)
    }
    if index < 26 {
      for start in [0x1D538, 0x1D49C] {
        let wide = codepoint_string(start + index)
        registry.define_symbol(Math, MathOrdGroup, text, wide)
        registry.define_symbol(Text, TextOrdGroup, text, wide)
      }
    }
  }
  let double_struck_k = codepoint_string(0x1D55C)
  registry.define_symbol(Math, MathOrdGroup, "k", double_struck_k)
  registry.define_symbol(Text, TextOrdGroup, "k", double_struck_k)
  for index, ch in "0123456789" {
    let text = String::from_array([ch])
    for start in [0x1D7CE, 0x1D7E2, 0x1D7EC, 0x1D7F6] {
      let wide = codepoint_string(start + index)
      registry.define_symbol(Math, MathOrdGroup, text, wide)
      registry.define_symbol(Text, TextOrdGroup, text, wide)
    }
  }
  for ch in "ÐÞþ" {
    let text = String::from_array([ch])
    registry.define_symbol(Math, MathOrdGroup, text, text)
    registry.define_symbol(Text, TextOrdGroup, text, text)
  }
  registry
}

///|
let builtin_symbols : SymbolRegistry = build_builtin_symbols()

///|
fn lookup_symbol(mode : Mode, name : String) -> SymbolSpec? {
  if mode == Math {
    builtin_symbols.math.get(name)
  } else {
    builtin_symbols.text.get(name)
  }
}

///|
fn is_registered_symbol(name : String) -> Bool {
  builtin_symbols.math.contains(name) || builtin_symbols.text.contains(name)
}
