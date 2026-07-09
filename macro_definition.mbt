///|
pub(all) enum MacroDefinition {
  Text(String)
  Expansion(tokens~ : Array[Token], num_args~ : Int, unexpandable~ : Bool)
} derive(Debug, ToJson, Eq)

///|
pub fn MacroDefinition::is_unexpandable(self : MacroDefinition) -> Bool {
  match self {
    Text(_) => false
    Expansion(unexpandable~, ..) => unexpandable
  }
}
