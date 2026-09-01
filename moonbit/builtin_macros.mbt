///|
priv enum MathSymbolGroup {
  BinarySymbol
  RelationSymbol
}

///|
type MathSymbolGroupResolver = (String) -> MathSymbolGroup?

///|
priv enum MacroLogEvent {
  MacroMessage(String)
  MacroErrorMessage(String)
  MacroShow(String)
}

///|
type MacroReporter = (MacroLogEvent) -> Unit

///|
fn default_math_symbol_group(name : String) -> MathSymbolGroup? {
  match lookup_symbol(Math, name) {
    Some({ group: BinaryGroup, .. }) => Some(BinarySymbol)
    Some({ group: RelationGroup, .. }) => Some(RelationSymbol)
    _ => None
  }
}

///|
fn default_macro_reporter(event : MacroLogEvent) -> Unit {
  match event {
    MacroMessage(message) | MacroErrorMessage(message) | MacroShow(message) =>
      println(message)
  }
}

///|
let builtin_dynamic_macro_definitions : Map[String, MacroHandler] = Map::from_array([
    ("\\noexpand", noexpand_macro),
    ("\\expandafter", expandafter_macro),
    ("\\@firstoftwo", first_of_two_macro),
    ("\\@secondoftwo", second_of_two_macro),
    ("\\@ifnextchar", if_next_char_macro),
    ("\\TextOrMath", text_or_math_macro),
    ("\\char", char_macro),
    ("\\newcommand", new_command_macro),
    ("\\renewcommand", renew_command_macro),
    ("\\providecommand", provide_command_macro),
    ("\\message", message_macro),
    ("\\errmessage", error_message_macro),
    ("\\show", show_macro),
    ("\\dots", dots_macro),
    ("\\dotso", dots_other_macro),
    ("\\dotsc", dots_comma_macro),
    ("\\cdots", centered_dots_macro),
    ("\\tag@literal", tag_literal_macro),
    ("\\bra@ket", braket_macro),
    ("\\bra@set", set_macro),
  ],
)

///|
fn builtin_dynamic_macros() -> Map[String, MacroHandler] {
  builtin_dynamic_macro_definitions
}

///|
fn token_expansion(tokens : Array[Token]) -> MacroReplacement {
  ReplacementExpansion(MacroExpansion::make(tokens))
}
