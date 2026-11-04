///|
fn base_element(node : ParseNode) -> ParseNode {
  match node {
    OrdGroup(body=[only], ..) => base_element(only)
    Color(body=[only], ..) => base_element(only)
    Font(body~, ..) => base_element(body)
    _ => node
  }
}

///|
fn is_character_box(node : ParseNode) -> Bool {
  match base_element(node) {
    MathOrd(..) | TextOrd(..) | Atom(..) => true
    _ => false
  }
}

///|
fn binrel_class(arg : ParseNode) -> AtomFamily {
  let atom = match arg {
    OrdGroup(body=[first, ..], ..) => first
    _ => arg
  }
  match atom {
    Atom(family=Mbin | Mrel as family, ..) => family
    _ => Mord
  }
}
