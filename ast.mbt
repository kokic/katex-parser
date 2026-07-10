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
  TextOrd(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
  MathOrd(mode~ : Mode, loc~ : SourceLocation?, text~ : String)
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
    OrdGroup(mode~, ..) => mode
    SupSub(mode~, ..) => mode
    TextOrd(mode~, ..) => mode
    MathOrd(mode~, ..) => mode
    Atom(mode~, ..) => mode
    Color(mode~, ..) => mode
  }
}
