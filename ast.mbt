///|
pub(all) enum Mode {
  Math
  Text
} derive(Debug, ToJson, Eq)

///|
pub(all) enum AtomFamily {
  Mord
  Mop
  Mbin
  Mrel
  Mopen
  Mclose
  Mpunct
  Minner
} derive(Debug, ToJson, Eq)

///|
pub(all) struct Measurement {
  number : Double
  unit : String
} derive(Debug, ToJson, Eq)

///|
pub(all) enum StyleLevel {
  DisplayStyle
  TextStyle
  ScriptStyle
  ScriptScriptStyle
} derive(Debug, ToJson, Eq)

///|
pub(all) enum OperatorContent {
  SymbolOperator(String)
  BodyOperator(Array[ParseNode])
  NamedOperator(String)
} derive(Debug, ToJson, Eq)

///|
pub(all) enum LapAlignment {
  LLap
  RLap
  CLap
} derive(Debug, ToJson, Eq)

///|
pub(all) enum ArrayColumn {
  AlignColumn(alignment~ : String, pre_gap~ : Double, post_gap~ : Double)
  SeparatorColumn(separator~ : String)
} derive(Debug, ToJson, Eq)

///|
pub(all) enum ColumnSeparationType {
  AlignSeparation
  AlignAtSeparation
  GatherSeparation
  SmallSeparation
  CdSeparation
} derive(Debug, ToJson, Eq)

///|
pub(all) enum ParseNode {
  Internal(mode~ : Mode)
  Raw(mode~ : Mode, string~ : String)
  ColorToken(mode~ : Mode, color~ : String)
  Size(mode~ : Mode, value~ : Measurement, is_blank~ : Bool)
  Url(mode~ : Mode, url~ : String)
  Styling(
    mode~ : Mode,
    body~ : Array[ParseNode],
    style~ : StyleLevel,
    reset_font~ : Bool
  )
  Sqrt(mode~ : Mode, body~ : ParseNode, index~ : ParseNode?)
  Infix(
    mode~ : Mode,
    replace_with~ : String,
    size~ : Measurement?,
    token~ : Token?
  )
  GenFrac(
    mode~ : Mode,
    numer~ : ParseNode,
    denom~ : ParseNode,
    continued~ : Bool,
    has_bar_line~ : Bool,
    bar_size~ : Measurement?,
    left_delim~ : String?,
    right_delim~ : String?
  )
  Text(mode~ : Mode, body~ : Array[ParseNode], font~ : String)
  Font(mode~ : Mode, font~ : String, body~ : ParseNode)
  MClass(
    mode~ : Mode,
    mclass~ : AtomFamily,
    body~ : Array[ParseNode],
    is_character_box~ : Bool
  )
  Op(
    mode~ : Mode,
    limits~ : Bool,
    always_handle_sup_sub~ : Bool,
    parent_is_sup_sub~ : Bool,
    suppress_base_shift~ : Bool,
    content~ : OperatorContent
  )
  OperatorName(
    mode~ : Mode,
    body~ : Array[ParseNode],
    always_handle_sup_sub~ : Bool,
    limits~ : Bool,
    parent_is_sup_sub~ : Bool
  )
  Overline(mode~ : Mode, body~ : ParseNode)
  Underline(mode~ : Mode, body~ : ParseNode)
  Smash(
    mode~ : Mode,
    body~ : ParseNode,
    smash_height~ : Bool,
    smash_depth~ : Bool
  )
  Phantom(mode~ : Mode, body~ : Array[ParseNode])
  VPhantom(mode~ : Mode, body~ : ParseNode)
  Pmb(mode~ : Mode, mclass~ : AtomFamily, body~ : Array[ParseNode])
  VCenter(mode~ : Mode, body~ : ParseNode)
  Rule(
    mode~ : Mode,
    shift~ : Measurement?,
    width~ : Measurement,
    height~ : Measurement
  )
  RaiseBox(mode~ : Mode, dy~ : Measurement, body~ : ParseNode)
  HBox(mode~ : Mode, body~ : Array[ParseNode])
  Lap(mode~ : Mode, alignment~ : LapAlignment, body~ : ParseNode)
  MathChoice(
    mode~ : Mode,
    display~ : Array[ParseNode],
    text~ : Array[ParseNode],
    script~ : Array[ParseNode],
    scriptscript~ : Array[ParseNode]
  )
  Sizing(mode~ : Mode, size~ : Int, body~ : Array[ParseNode])
  HorizBrace(mode~ : Mode, label~ : String, is_over~ : Bool, base~ : ParseNode)
  XArrow(mode~ : Mode, label~ : String, body~ : ParseNode, below~ : ParseNode?)
  AccentUnder(mode~ : Mode, label~ : String, base~ : ParseNode)
  DelimSizing(mode~ : Mode, size~ : Int, mclass~ : AtomFamily, delim~ : String)
  LeftRightRight(mode~ : Mode, delim~ : String, color~ : String?)
  LeftRight(
    mode~ : Mode,
    body~ : Array[ParseNode],
    left~ : String,
    right~ : String,
    right_color~ : String?
  )
  Middle(mode~ : Mode, delim~ : String)
  Kern(mode~ : Mode, dimension~ : Measurement)
  Enclose(
    mode~ : Mode,
    body~ : ParseNode,
    label~ : String,
    background_color~ : String?,
    border_color~ : String?
  )
  Href(mode~ : Mode, href~ : String, body~ : Array[ParseNode])
  Html(
    mode~ : Mode,
    attributes~ : Map[String, String],
    body~ : Array[ParseNode]
  )
  IncludeGraphics(
    mode~ : Mode,
    alt~ : String,
    width~ : Measurement,
    height~ : Measurement,
    totalheight~ : Measurement,
    src~ : String
  )
  Tag(mode~ : Mode, body~ : Array[ParseNode], tag~ : Array[ParseNode])
  Array(
    mode~ : Mode,
    body~ : Array[Array[ParseNode]],
    add_jot~ : Bool,
    array_stretch~ : Double,
    columns~ : Array[ArrayColumn]?,
    row_gaps~ : Array[Measurement?],
    hskip_before_and_after~ : Bool,
    hlines_before_row~ : Array[Array[Bool]],
    column_separation_type~ : ColumnSeparationType?,
    tags~ : Array[Array[ParseNode]?]?,
    auto_tags~ : Array[Bool]?,
    leqno~ : Bool
  )
  EnvironmentEnd(mode~ : Mode, name~ : String)
  Cr(mode~ : Mode, new_line~ : Bool, size~ : Measurement?)
  HtmlMathML(mode~ : Mode, html~ : Array[ParseNode], mathml~ : Array[ParseNode])
  OrdGroup(
    mode~ : Mode,
    loc~ : SourceLocation?,
    body~ : Array[ParseNode],
    semisimple~ : Bool
  )
  SupSub(mode~ : Mode, base~ : ParseNode?, sup~ : ParseNode?, sub~ : ParseNode?)
  TextOrd(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  MathOrd(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  Spacing(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  AccentToken(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  OperatorToken(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  Accent(
    mode~ : Mode,
    loc~ : SourceLocation?,
    label~ : String,
    is_stretchy~ : Bool,
    is_shifty~ : Bool,
    base~ : ParseNode
  )
  Verb(mode~ : Mode, loc~ : SourceLocation?, body~ : String, star~ : Bool)
  Atom(
    mode~ : Mode,
    loc~ : SourceLocation?,
    family~ : AtomFamily,
    text~ : String
  )
  Color(mode~ : Mode, color~ : String, body~ : Array[ParseNode])
} derive(Debug, ToJson, Eq)

///|
pub fn ParseNode::mode(self : ParseNode) -> Mode {
  match self {
    Internal(mode~) => mode
    Raw(mode~, ..) => mode
    ColorToken(mode~, ..) => mode
    Size(mode~, ..) => mode
    Url(mode~, ..) => mode
    Styling(mode~, ..) => mode
    Sqrt(mode~, ..) => mode
    Infix(mode~, ..) => mode
    GenFrac(mode~, ..) => mode
    Text(mode~, ..) => mode
    Font(mode~, ..) => mode
    MClass(mode~, ..) => mode
    Op(mode~, ..) => mode
    OperatorName(mode~, ..) => mode
    Overline(mode~, ..) => mode
    Underline(mode~, ..) => mode
    Smash(mode~, ..) => mode
    Phantom(mode~, ..) => mode
    VPhantom(mode~, ..) => mode
    Pmb(mode~, ..) => mode
    VCenter(mode~, ..) => mode
    Rule(mode~, ..) => mode
    RaiseBox(mode~, ..) => mode
    HBox(mode~, ..) => mode
    Lap(mode~, ..) => mode
    MathChoice(mode~, ..) => mode
    Sizing(mode~, ..) => mode
    HorizBrace(mode~, ..) => mode
    XArrow(mode~, ..) => mode
    AccentUnder(mode~, ..) => mode
    DelimSizing(mode~, ..) => mode
    LeftRightRight(mode~, ..) => mode
    LeftRight(mode~, ..) => mode
    Middle(mode~, ..) => mode
    Kern(mode~, ..) => mode
    Enclose(mode~, ..) => mode
    Href(mode~, ..) => mode
    Html(mode~, ..) => mode
    IncludeGraphics(mode~, ..) => mode
    Tag(mode~, ..) => mode
    Array(mode~, ..) => mode
    EnvironmentEnd(mode~, ..) => mode
    Cr(mode~, ..) => mode
    HtmlMathML(mode~, ..) => mode
    OrdGroup(mode~, ..) => mode
    SupSub(mode~, ..) => mode
    TextOrd(mode~, ..) => mode
    MathOrd(mode~, ..) => mode
    Spacing(mode~, ..) => mode
    AccentToken(mode~, ..) => mode
    OperatorToken(mode~, ..) => mode
    Accent(mode~, ..) => mode
    Verb(mode~, ..) => mode
    Atom(mode~, ..) => mode
    Color(mode~, ..) => mode
  }
}
