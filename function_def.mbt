///|
fn internal_node(context : FunctionContext) -> ParseNode {
  Internal(mode=context.mode)
}

///|
fn check_control_sequence(token : Token) -> String raise ParseFailure {
  match token.text {
    "\\" | "{" | "}" | "$" | "&" | "#" | "^" | "_" | "EOF" =>
      raise InvalidArgument(
        message="Expected a control sequence",
        loc=token.loc,
      )
    name => name
  }
}

///|
fn macro_prefix_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\global", "\\long", "\\\\globallong"],
    0,
    allowed_in_text=true,
    handler=macro_prefix_handler,
  )
}

///|
fn prefixed_macro_name(prefix : String, next : String) -> String? {
  let global = prefix == "\\global" || prefix == "\\\\globallong"
  match next {
    "\\global" => Some("\\global")
    "\\long" => Some(if global { "\\\\globallong" } else { "\\long" })
    "\\\\globallong" => Some("\\\\globallong")
    "\\def" => Some(if global { "\\gdef" } else { "\\def" })
    "\\gdef" => Some("\\gdef")
    "\\edef" => Some(if global { "\\xdef" } else { "\\edef" })
    "\\xdef" => Some("\\xdef")
    "\\let" => Some(if global { "\\\\globallet" } else { "\\let" })
    "\\futurelet" =>
      Some(if global { "\\\\globalfuture" } else { "\\futurelet" })
    _ => None
  }
}

///|
fn macro_prefix_handler(
  context : FunctionContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  (context.consume_spaces)()
  let token = (context.pop_token)()
  match prefixed_macro_name(context.func_name, token.text) {
    Some(name) => (context.parse_prefixed_function)(name)
    None =>
      raise InvalidArgument(
        message="Invalid token after macro prefix",
        loc=token.loc,
      )
  }
}

///|
fn definition_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\def", "\\gdef", "\\edef", "\\xdef"],
    0,
    allowed_in_text=true,
    primitive=true,
    handler=definition_handler,
  )
}

///|
fn definition_handler(
  context : FunctionContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let name = check_control_sequence((context.pop_token)())
  let delimiters : Array[Array[String]] = [[]]
  let mut count = 0
  let mut insert : Token? = None
  while (context.future_token)().text != "{" {
    let token = (context.pop_token)()
    if token.text == "#" {
      if (context.future_token)().text == "{" {
        let brace = (context.future_token)()
        delimiters[count].push("{")
        insert = Some(brace)
        break
      }
      let number = (context.pop_token)()
      if number.text.length() != 1 ||
        number.text[0] < '1' ||
        number.text[0] > '9' {
        raise InvalidArgument(
          message="Invalid argument number \"" + number.text + "\"",
          loc=number.loc,
        )
      }
      if number.text[0].to_int() - ('0' : UInt16).to_int() != count + 1 {
        raise InvalidArgument(
          message="Argument number \"" + number.text + "\" out of order",
          loc=number.loc,
        )
      }
      count = count + 1
      delimiters.push([])
    } else if token.text == "EOF" {
      raise InvalidArgument(
        message="Expected a macro definition",
        loc=token.loc,
      )
    } else {
      delimiters[count].push(token.text)
    }
  }
  let mut tokens = (context.consume_macro_arg)()
  match insert {
    Some(token) => {
      let prefixed = [token]
      prefixed.append(tokens)
      tokens = prefixed
    }
    None => ()
  }
  let tokens = if context.func_name == "\\edef" || context.func_name == "\\xdef" {
    let expanded = (context.expand_tokens)(tokens)
    expanded.rev_in_place()
    expanded
  } else {
    tokens
  }
  (context.set_macro_definition)(
    name,
    MacroDefinition::expansion(
      MacroExpansion::make(tokens, num_args=count, delimiters~),
    ),
    context.func_name == "\\gdef" || context.func_name == "\\xdef",
  )
  internal_node(context)
}

///|
fn let_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\let", "\\\\globallet"],
    0,
    allowed_in_text=true,
    primitive=true,
    handler=let_handler,
  )
}

///|
fn let_rhs(context : FunctionContext) -> Token raise ParseFailure {
  let mut token = (context.pop_token)()
  if token.text == "=" {
    token = (context.pop_token)()
    if token.text == " " {
      token = (context.pop_token)()
    }
  }
  token
}

///|
fn assign_let(
  context : FunctionContext,
  name : String,
  token : Token,
  global : Bool,
) -> Unit {
  let definition = match (context.get_macro)(token.text) {
    Some(value) => value
    None => {
      token.noexpand = true
      MacroDefinition::expansion(
        MacroExpansion::make(
          [token],
          unexpandable=!(context.is_expandable)(token.text),
        ),
      )
    }
  }
  (context.set_macro_definition)(name, definition, global)
}

///|
fn let_handler(
  context : FunctionContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let name = check_control_sequence((context.pop_token)())
  (context.consume_spaces)()
  assign_let(
    context,
    name,
    let_rhs(context),
    context.func_name == "\\\\globallet",
  )
  internal_node(context)
}

///|
fn futurelet_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\futurelet", "\\\\globalfuture"],
    0,
    allowed_in_text=true,
    primitive=true,
    handler=futurelet_handler,
  )
}

///|
fn futurelet_handler(
  context : FunctionContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let name = check_control_sequence((context.pop_token)())
  let middle = (context.pop_token)()
  let token = (context.pop_token)()
  assign_let(context, name, token, context.func_name == "\\\\globalfuture")
  (context.push_token)(token)
  (context.push_token)(middle)
  internal_node(context)
}
