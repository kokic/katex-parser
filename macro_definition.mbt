///|
pub(all) enum MacroDefinition {
  Text(String)
} derive(Debug, ToJson, Eq)

///|
priv struct MacroArgument {
  start : Token
  end : Token
  tokens : Array[Token]
}

///|
