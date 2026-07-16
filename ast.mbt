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
