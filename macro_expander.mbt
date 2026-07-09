///|
pub(all) struct MacroExpander {
  settings : Settings
  mut expansion_count : Int
  mut lexer : Lexer
  macros : Namespace[MacroDefinition]
  stack : Array[Token]
  mut mode : Mode
} derive(Debug)

///|
pub fn MacroExpander::make(
  input : String,
  settings : Settings,
  mode : Mode,
) -> MacroExpander {
  {
    settings,
    expansion_count: 0,
    lexer: Lexer::make(input, settings),
    macros: Namespace::make(builtin_macros(), settings.macros),
    stack: [],
    mode,
  }
}

///|
fn builtin_macros() -> Map[String, MacroDefinition] {
  { "\\relax": Text("\\relax") }
}

///|
pub fn MacroExpander::feed(self : MacroExpander, input : String) -> Unit {
  self.lexer = Lexer::make(input, self.settings)
}

///|
pub fn MacroExpander::switch_mode(
  self : MacroExpander,
  new_mode : Mode,
) -> Unit {
  self.mode = new_mode
}

///|
pub fn MacroExpander::begin_group(self : MacroExpander) -> Unit {
  self.macros.begin_group()
}

///|
pub fn MacroExpander::end_group(self : MacroExpander) -> Unit {
  self.macros.end_group()
}

///|
pub fn MacroExpander::end_groups(self : MacroExpander) -> Unit {
  self.macros.end_groups()
}

///|
pub fn MacroExpander::future(self : MacroExpander) -> ParseResult[Token] {
  if self.stack.is_empty() {
    match self.lexer.lex() {
      Ok(token) => {
        self.stack.push(token)
        Ok(token)
      }
      Err(err) => Err(err)
    }
  } else {
    match self.stack.last() {
      Some(token) => Ok(token)
      None => Err(Generic(message="Empty token stack", token=None))
    }
  }
}

///|
pub fn MacroExpander::pop_token(self : MacroExpander) -> ParseResult[Token] {
  match self.future() {
    Ok(_) =>
      match self.stack.pop() {
        Some(token) => Ok(token)
        None => Err(Generic(message="Empty token stack", token=None))
      }
    Err(err) => Err(err)
  }
}

///|
pub fn MacroExpander::push_token(self : MacroExpander, token : Token) -> Unit {
  self.stack.push(token)
}

///|
pub fn MacroExpander::push_tokens(
  self : MacroExpander,
  tokens : Array[Token],
) -> Unit {
  self.stack.append(tokens)
}

///|
pub fn MacroExpander::consume_spaces(self : MacroExpander) -> ParseResult[Unit] {
  for ;; {
    match self.future() {
      Ok(token) =>
        if token.text == " " {
          ignore(self.stack.pop())
          continue
        } else {
          break Ok(())
        }
      Err(err) => break Err(err)
    }
  }
}

///|
pub fn MacroExpander::count_expansion(
  self : MacroExpander,
  amount : Int,
) -> ParseResult[Unit] {
  self.expansion_count = self.expansion_count + amount
  if self.expansion_count > self.settings.max_expand {
    Err(TooManyExpansions(limit=self.settings.max_expand))
  } else {
    Ok(())
  }
}

///|
pub fn MacroExpander::expand_once(
  self : MacroExpander,
  expandable_only? : Bool = false,
) -> ParseResult[Bool] {
  match self.pop_token() {
    Err(err) => Err(err)
    Ok(top_token) => {
      let name = top_token.text
      let expansion = if top_token.noexpand {
        None
      } else {
        self.get_expansion(name)
      }
      match expansion {
        None =>
          if expandable_only &&
            name.length() > 0 &&
            name[0] == '\\' &&
            !self.is_defined(name) {
            Err(UndefinedControlSequence(name~, token=top_token))
          } else {
            self.push_token(top_token)
            Ok(false)
          }
        Some(tokens) =>
          match self.count_expansion(1) {
            Err(err) => Err(err)
            Ok(_) => {
              self.push_tokens(tokens)
              Ok(true)
            }
          }
      }
    }
  }
}

///|
pub fn MacroExpander::expand_next_token(
  self : MacroExpander,
) -> ParseResult[Token] {
  for ;; {
    match self.expand_once() {
      Err(err) => break Err(err)
      Ok(false) =>
        match self.stack.pop() {
          Some(token) => {
            if token.treat_as_relax {
              token.text = "\\relax"
            }
            break Ok(token)
          }
          None => break Err(Generic(message="Empty token stack", token=None))
        }
      Ok(true) => continue
    }
  }
}

///|
fn MacroExpander::get_expansion(
  self : MacroExpander,
  name : String,
) -> Array[Token]? {
  match self.macros.get(name) {
    None => None
    Some(definition) =>
      match definition {
        Text(expansion) =>
          Some(tokens_from_macro_text(expansion, self.settings))
        Expansion(tokens~, unexpandable~, ..) =>
          if unexpandable {
            None
          } else {
            Some(tokens.copy())
          }
      }
  }
}

///|
fn tokens_from_macro_text(
  expansion : String,
  settings : Settings,
) -> Array[Token] {
  let lexer = Lexer::make(expansion, settings)
  let tokens : Array[Token] = []
  for ;; {
    match lexer.lex() {
      Ok(token) =>
        if token.text == "EOF" {
          break
        } else {
          tokens.push(token)
          continue
        }
      Err(_) => break
    }
  }
  tokens.rev()
}

///|
pub fn MacroExpander::is_defined(self : MacroExpander, name : String) -> Bool {
  self.macros.has(name) || implicit_commands().contains(name)
}

///|
pub fn MacroExpander::is_expandable(
  self : MacroExpander,
  name : String,
) -> Bool {
  match self.macros.get(name) {
    Some(definition) => !definition.is_unexpandable()
    None => false
  }
}

///|
fn implicit_commands() -> Map[String, Bool] {
  { "^": true, "_": true, "\\limits": true, "\\nolimits": true }
}
