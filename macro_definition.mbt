///|
priv struct MacroExpansion {
  tokens : Array[Token]
  num_args : Int
  delimiters : Array[Array[String]]?
  unexpandable : Bool
}

///|
priv enum MacroDefinition {
  Text(String)
  Expansion(MacroExpansion)
}

///|
fn MacroDefinition::text(expansion : String) -> MacroDefinition {
  Text(expansion)
}

///|
fn MacroDefinition::to_source(self : MacroDefinition) -> String {
  match self {
    Text(expansion) => expansion
    Expansion(expansion) => expansion.to_source()
  }
}

///|
fn MacroExpansion::to_source(self : MacroExpansion) -> String {
  let tokens = self.tokens.rev()
  let builder = StringBuilder()
  for token in tokens {
    builder.write_string(token.text)
  }
  builder.to_string()
}

///|
#warnings("-unused_value")
fn MacroDefinition::expansion(expansion : MacroExpansion) -> MacroDefinition {
  Expansion(expansion)
}

///|
fn MacroExpansion::make(
  tokens : Array[Token],
  num_args? : Int = 0,
  delimiters? : Array[Array[String]],
  unexpandable? : Bool = false,
) -> MacroExpansion {
  { tokens, num_args, delimiters, unexpandable }
}

///|
priv struct MacroArgument {
  start : Token
  end : Token
  tokens : Array[Token]
}
