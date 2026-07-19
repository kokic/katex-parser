///|
/// True if the Unicode rendering has no internal operator that needs grouping.
///
/// A node is atomic when its rendered output is either a single token/character
/// or uses self-delimiting function-application notation.
fn is_atomic_expression(node : @katex_parser.ParseNode) -> Bool {
  match node {
    // --- Single-token leaf nodes ---
    Raw(..)
    | ColorToken(..)
    | TextOrd(..)
    | MathOrd(..)
    | Spacing(..)
    | AccentToken(..)
    | OperatorToken(..)
    | Atom(..)
    | Op(..)
    | OperatorName(..)
    | LeftRight(..)
    | Font(..)
    | DelimSizing(..)
    | LeftRightRight(..)
    | Middle(..) => true
    // --- Self-delimiting function notation (no external parens needed) ---
    Sqrt(..)
    | Overline(..)
    | Underline(..)
    | Phantom(..)
    | Pmb(..)
    | Kern(..)
    | Enclose(..)
    | Rule(..)
    | IncludeGraphics(..)
    | AccentUnder(..)
    | CdLabel(..) => true
    // --- Body-array wrappers (atomic iff single child is atomic) ---
    Styling(body~, ..)
    | Text(body~, ..)
    | MClass(body~, ..)
    | HBox(body~, ..)
    | Sizing(body~, ..)
    | Color(body~, ..)
    | Href(body~, ..)
    | Html(body~, ..)
    | OrdGroup(body~, ..) => body.length() == 1 && is_atomic_expression(body[0])
    // --- Transparent single-body wrappers (delegate to body) ---
    Accent(base~, ..) => is_atomic_expression(base)
    Smash(body~, ..)
    | VPhantom(body~, ..)
    | VCenter(body~, ..)
    | RaiseBox(body~, ..)
    | Lap(body~, ..) => is_atomic_expression(body)
    CdParent(fragment~, ..) => is_atomic_expression(fragment)
    _ => false
  }
}
