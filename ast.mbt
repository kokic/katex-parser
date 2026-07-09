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
pub(all) enum ParseNode {
  OrdGroup(
    mode~ : Mode,
    loc~ : SourceLocation?,
    body~ : Array[ParseNode],
    semisimple~ : Bool
  )
  SupSub(mode~ : Mode, base~ : ParseNode?, sup~ : ParseNode?, sub~ : ParseNode?)
  Text(mode~ : Mode, body~ : Array[ParseNode], font~ : String?)
  TextOrd(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  MathOrd(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  Atom(
    mode~ : Mode,
    loc~ : SourceLocation?,
    family~ : AtomFamily,
    text~ : String
  )
  Spacing(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  AccentToken(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  OpToken(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  Color(mode~ : Mode, color~ : String, body~ : Array[ParseNode])
  ColorToken(mode~ : Mode, color~ : String)
  Size(mode~ : Mode, value~ : Measurement, is_blank~ : Bool)
  Raw(mode~ : Mode, string~ : String)
  Url(mode~ : Mode, url~ : String)
  Styling(
    mode~ : Mode,
    style~ : String,
    reset_font~ : Bool,
    body~ : Array[ParseNode]
  )
  Infix(mode~ : Mode, replace_with~ : String, token~ : Token?)
  Internal(mode~ : Mode)
  Unsupported(mode~ : Mode, text~ : String)
} derive(Debug, ToJson, Eq)

///|
pub(all) struct Measurement {
  number : Double
  unit : String
} derive(Debug, ToJson, Eq)

///|
pub fn ParseNode::mode(self : ParseNode) -> Mode {
  match self {
    OrdGroup(mode~, ..) => mode
    SupSub(mode~, ..) => mode
    Text(mode~, ..) => mode
    TextOrd(mode~, ..) => mode
    MathOrd(mode~, ..) => mode
    Atom(mode~, ..) => mode
    Spacing(mode~, ..) => mode
    AccentToken(mode~, ..) => mode
    OpToken(mode~, ..) => mode
    Color(mode~, ..) => mode
    ColorToken(mode~, ..) => mode
    Size(mode~, ..) => mode
    Raw(mode~, ..) => mode
    Url(mode~, ..) => mode
    Styling(mode~, ..) => mode
    Infix(mode~, ..) => mode
    Internal(mode~) => mode
    Unsupported(mode~, ..) => mode
  }
}
