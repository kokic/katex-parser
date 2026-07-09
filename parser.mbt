///|
pub(all) struct Parser {
  mut mode : Mode
  gullet : MacroExpander
  settings : Settings
  mut leftright_depth : Int
  mut next_token : Token?
} derive(Debug)

///|
pub fn Parser::make(input : String, settings : Settings) -> Parser {
  {
    mode: Math,
    gullet: MacroExpander::make(input, settings, Math),
    settings,
    leftright_depth: 0,
    next_token: None,
  }
}

///|
pub fn parse(
  input : String,
  settings? : Settings = Settings::default(),
) -> ParseResult[Array[ParseNode]] {
  let parser = Parser::make(input, settings)
  parser.parse()
}

///|
pub fn Parser::fetch(self : Parser) -> ParseResult[Token] {
  match self.next_token {
    Some(token) => Ok(token)
    None =>
      match self.gullet.expand_next_token() {
        Ok(token) => {
          self.next_token = Some(token)
          Ok(token)
        }
        Err(err) => Err(err)
      }
  }
}

///|
pub fn Parser::consume(self : Parser) -> Unit {
  self.next_token = None
}

///|
pub fn Parser::expect(
  self : Parser,
  text : String,
  consume? : Bool = true,
) -> ParseResult[Unit] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(token) =>
      if token.text == text {
        if consume {
          self.consume()
        }
        Ok(())
      } else {
        Err(ExpectedToken(expected=text, actual=token))
      }
  }
}

///|
pub fn Parser::switch_mode(self : Parser, new_mode : Mode) -> Unit {
  self.mode = new_mode
  self.gullet.switch_mode(new_mode)
}

///|
pub fn Parser::parse(self : Parser) -> ParseResult[Array[ParseNode]] {
  if !self.settings.global_group {
    self.gullet.begin_group()
  }
  let parsed = self.parse_expression(false, None)
  let result = match parsed {
    Err(err) => Err(err)
    Ok(body) =>
      match self.expect("EOF") {
        Err(err) => Err(err)
        Ok(_) => Ok(body)
      }
  }
  if !self.settings.global_group {
    self.gullet.end_group()
  }
  self.gullet.end_groups()
  result
}

///|
pub fn Parser::parse_expression(
  self : Parser,
  break_on_infix : Bool,
  break_on_token_text : String?,
) -> ParseResult[Array[ParseNode]] {
  let body : Array[ParseNode] = []
  for ;; {
    if self.mode == Math {
      match self.consume_spaces() {
        Err(err) => break Err(err)
        Ok(_) => ()
      }
    }
    match self.fetch() {
      Err(err) => break Err(err)
      Ok(token) =>
        if is_end_of_expression(token.text) {
          break Ok(self.finish_expression(body))
        } else if break_on_token_text is Some(stop) && token.text == stop {
          break Ok(self.finish_expression(body))
        } else if break_on_infix && is_infix_function(token.text) {
          break Ok(self.finish_expression(body))
        } else {
          match self.parse_atom(break_on_token_text) {
            Err(err) => break Err(err)
            Ok(None) => break Ok(self.finish_expression(body))
            Ok(Some(node)) =>
              match node {
                Internal(_) => continue
                _ => {
                  body.push(node)
                  continue
                }
              }
          }
        }
    }
  }
}

///|
fn Parser::finish_expression(
  self : Parser,
  body : Array[ParseNode],
) -> Array[ParseNode] {
  if self.mode == Text {
    form_ligatures(body)
  }
  self.handle_infix_nodes(body)
}

///|
fn is_end_of_expression(text : String) -> Bool {
  text == "}" ||
  text == "\\endgroup" ||
  text == "\\end" ||
  text == "\\right" ||
  text == "&"
}

///|
fn is_infix_function(text : String) -> Bool {
  text == "\\over" ||
  text == "\\atop" ||
  text == "\\choose" ||
  text == "\\above"
}

///|
pub fn Parser::consume_spaces(self : Parser) -> ParseResult[Unit] {
  for ;; {
    match self.fetch() {
      Err(err) => break Err(err)
      Ok(token) =>
        if token.text == " " {
          self.consume()
          continue
        } else {
          break Ok(())
        }
    }
  }
}

///|
pub fn Parser::parse_atom(
  self : Parser,
  break_on_token_text : String?,
) -> ParseResult[ParseNode?] {
  match self.parse_group("atom", break_on_token_text) {
    Err(err) => Err(err)
    Ok(None) => Ok(None)
    Ok(Some(base)) =>
      match base {
        Internal(_) => Ok(Some(base))
        _ =>
          if self.mode == Text {
            Ok(Some(base))
          } else {
            self.parse_scripts(base)
          }
      }
  }
}

///|
fn Parser::parse_scripts(
  self : Parser,
  base : ParseNode,
) -> ParseResult[ParseNode?] {
  let mut sup : ParseNode? = None
  let mut sub : ParseNode? = None
  for ;; {
    match self.consume_spaces() {
      Err(err) => break Err(err)
      Ok(_) => ()
    }
    match self.fetch() {
      Err(err) => break Err(err)
      Ok(token) =>
        if token.text == "^" {
          if sup is Some(_) {
            break Err(Generic(message="Double superscript", token=Some(token)))
          }
          match self.handle_sup_subscript("superscript") {
            Err(err) => break Err(err)
            Ok(group) => {
              sup = Some(group)
              continue
            }
          }
        } else if token.text == "_" {
          if sub is Some(_) {
            break Err(Generic(message="Double subscript", token=Some(token)))
          }
          match self.handle_sup_subscript("subscript") {
            Err(err) => break Err(err)
            Ok(group) => {
              sub = Some(group)
              continue
            }
          }
        } else {
          break Ok(Some(make_supsub_or_base(self.mode, base, sup, sub)))
        }
    }
  }
}

///|
fn make_supsub_or_base(
  mode : Mode,
  base : ParseNode,
  sup : ParseNode?,
  sub : ParseNode?,
) -> ParseNode {
  match (sup, sub) {
    (None, None) => base
    _ => SupSub(mode~, base=Some(base), sup~, sub~)
  }
}

///|
pub fn Parser::handle_sup_subscript(
  self : Parser,
  name : String,
) -> ParseResult[ParseNode] {
  let symbol_token = self.fetch()
  match symbol_token {
    Err(err) => Err(err)
    Ok(token) => {
      self.consume()
      match self.consume_spaces() {
        Err(err) => Err(err)
        Ok(_) =>
          match self.parse_group(name, None) {
            Err(err) => Err(err)
            Ok(Some(group)) => Ok(group)
            Ok(None) =>
              Err(
                Generic(
                  message="Expected group after '" + token.text + "'",
                  token=Some(token),
                ),
              )
          }
      }
    }
  }
}

///|
pub fn Parser::parse_group(
  self : Parser,
  name : String,
  break_on_token_text : String?,
) -> ParseResult[ParseNode?] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(first_token) => {
      let text = first_token.text
      if text == "{" || text == "\\begingroup" {
        self.consume()
        let group_end = if text == "{" { "}" } else { "\\endgroup" }
        self.gullet.begin_group()
        let expression = self.parse_expression(false, Some(group_end))
        match expression {
          Err(err) => Err(err)
          Ok(body) => {
            let last_token = self.fetch()
            match last_token {
              Err(err) => Err(err)
              Ok(last) =>
                match self.expect(group_end) {
                  Err(err) => Err(err)
                  Ok(_) => {
                    self.gullet.end_group()
                    let loc = match (first_token.loc, last.loc) {
                      (Some(start_loc), Some(end_loc)) =>
                        Some(SourceLocation::range(start_loc, end_loc))
                      _ => None
                    }
                    Ok(
                      Some(
                        OrdGroup(
                          mode=self.mode,
                          loc~,
                          body~,
                          semisimple=text == "\\begingroup",
                        ),
                      ),
                    )
                  }
                }
            }
          }
        }
      } else {
        match self.parse_function(break_on_token_text, Some(name)) {
          Err(err) => Err(err)
          Ok(Some(node)) => Ok(Some(node))
          Ok(None) =>
            match self.parse_symbol() {
              Err(err) => Err(err)
              Ok(Some(node)) => Ok(Some(node))
              Ok(None) =>
                if text.length() > 0 && text[0] == '\\' {
                  if self.settings.throw_on_error {
                    Err(UndefinedControlSequence(name=text, token=first_token))
                  } else {
                    self.consume()
                    Ok(Some(Unsupported(mode=self.mode, text~)))
                  }
                } else {
                  Ok(None)
                }
            }
        }
      }
    }
  }
}

///|
pub fn Parser::parse_function(
  self : Parser,
  break_on_token_text : String?,
  name : String?,
) -> ParseResult[ParseNode?] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(token) => {
      let funcs = registered_functions()
      match funcs.get(token.text) {
        None => Ok(None)
        Some(func_data) => {
          self.consume()
          if name is Some(context_name) &&
            context_name != "atom" &&
            !func_data.allowed_in_argument {
            Err(
              Generic(
                message="Got function '" +
                  token.text +
                  "' with no arguments as " +
                  context_name,
                token=Some(token),
              ),
            )
          } else if self.mode == Text && !func_data.allowed_in_text {
            Err(
              Generic(
                message="Can't use function '" + token.text + "' in text mode",
                token=Some(token),
              ),
            )
          } else if self.mode == Math && !func_data.allowed_in_math {
            Err(
              Generic(
                message="Can't use function '" + token.text + "' in math mode",
                token=Some(token),
              ),
            )
          } else {
            match self.parse_arguments(token.text, func_data) {
              Err(err) => Err(err)
              Ok((args, opt_args)) =>
                match
                  self.call_function(
                    token.text,
                    args,
                    opt_args,
                    Some(token),
                    break_on_token_text,
                  ) {
                  Err(err) => Err(err)
                  Ok(node) => Ok(Some(node))
                }
            }
          }
        }
      }
    }
  }
}

///|
pub fn Parser::call_function(
  self : Parser,
  func_name : String,
  args : Array[ParseNode],
  opt_args : Array[ParseNode?],
  token : Token?,
  break_on_token_text : String?,
) -> ParseResult[ParseNode] {
  match registered_functions().get(func_name) {
    None => Err(Generic(message="No function handler for " + func_name, token~))
    Some(spec) => {
      let context = { func_name, parser: self, token, break_on_token_text }
      (spec.handler)(context, args, opt_args)
    }
  }
}

///|
pub fn Parser::parse_arguments(
  _self : Parser,
  func : String,
  func_data : FunctionSpec,
) -> ParseResult[(Array[ParseNode], Array[ParseNode?])] {
  if func_data.num_args == 0 && func_data.num_optional_args == 0 {
    Ok(([], []))
  } else {
    Err(
      Generic(
        message="Argument parsing is not implemented yet for " + func,
        token=None,
      ),
    )
  }
}

///|
pub fn Parser::parse_symbol(self : Parser) -> ParseResult[ParseNode?] {
  match self.fetch() {
    Err(err) => Err(err)
    Ok(token) => {
      let text = token.text
      if text == "EOF" ||
        text == "^" ||
        text == "_" ||
        text == "{" ||
        text == "}" ||
        text == "&" {
        Ok(None)
      } else if text.length() > 0 && text[0] == '\\' {
        Ok(None)
      } else {
        self.consume()
        Ok(Some(make_symbol_node(self.mode, text, token.loc)))
      }
    }
  }
}

///|
fn make_symbol_node(
  mode : Mode,
  text : String,
  loc : SourceLocation?,
) -> ParseNode {
  if mode == Text {
    TextOrd(mode~, loc~, text~)
  } else if is_binary_operator(text) {
    Atom(mode~, loc~, family=Mbin, text~)
  } else if is_relation_operator(text) {
    Atom(mode~, loc~, family=Mrel, text~)
  } else {
    MathOrd(mode~, loc~, text~)
  }
}

///|
fn is_binary_operator(text : String) -> Bool {
  text == "+" || text == "-" || text == "*" || text == "/"
}

///|
fn is_relation_operator(text : String) -> Bool {
  text == "=" || text == "<" || text == ">"
}

///|
pub fn Parser::handle_infix_nodes(
  _self : Parser,
  body : Array[ParseNode],
) -> Array[ParseNode] {
  body
}

///|
fn form_ligatures(_body : Array[ParseNode]) -> Unit {
  ()
}
