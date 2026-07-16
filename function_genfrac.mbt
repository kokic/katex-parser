///|
priv struct GenFracConfig {
  continued : Bool
  has_bar_line : Bool
  left_delim : String?
  right_delim : String?
  style : StyleLevel?
}

///|
fn wrap_genfrac_style(node : ParseNode, style : StyleLevel?) -> ParseNode {
  match style {
    None => node
    Some(value) =>
      Styling(mode=node.mode(), body=[node], style=value, reset_font=false)
  }
}

///|
fn standard_genfrac_config(
  func_name : String,
) -> GenFracConfig raise ParseFailure {
  match func_name {
    "\\cfrac" =>
      {
        continued: true,
        has_bar_line: true,
        left_delim: None,
        right_delim: None,
        style: Some(DisplayStyle),
      }
    "\\dfrac" =>
      {
        continued: false,
        has_bar_line: true,
        left_delim: None,
        right_delim: None,
        style: Some(DisplayStyle),
      }
    "\\frac" =>
      {
        continued: false,
        has_bar_line: true,
        left_delim: None,
        right_delim: None,
        style: None,
      }
    "\\tfrac" =>
      {
        continued: false,
        has_bar_line: true,
        left_delim: None,
        right_delim: None,
        style: Some(TextStyle),
      }
    "\\dbinom" =>
      {
        continued: false,
        has_bar_line: false,
        left_delim: Some("("),
        right_delim: Some(")"),
        style: Some(DisplayStyle),
      }
    "\\binom" =>
      {
        continued: false,
        has_bar_line: false,
        left_delim: Some("("),
        right_delim: Some(")"),
        style: None,
      }
    "\\tbinom" =>
      {
        continued: false,
        has_bar_line: false,
        left_delim: Some("("),
        right_delim: Some(")"),
        style: Some(TextStyle),
      }
    "\\\\atopfrac" =>
      {
        continued: false,
        has_bar_line: false,
        left_delim: None,
        right_delim: None,
        style: None,
      }
    "\\\\bracefrac" =>
      {
        continued: false,
        has_bar_line: false,
        left_delim: Some("\\{"),
        right_delim: Some("\\}"),
        style: None,
      }
    "\\\\brackfrac" =>
      {
        continued: false,
        has_bar_line: false,
        left_delim: Some("["),
        right_delim: Some("]"),
        style: None,
      }
    _ =>
      raise InternalInvariant(
        message="Unrecognized standard genfrac command: " + func_name,
      )
  }
}

///|
fn standard_genfrac_spec() -> FunctionSpec {
  FunctionSpec::make(
    [
      "\\cfrac", "\\dfrac", "\\frac", "\\tfrac", "\\dbinom", "\\binom", "\\tbinom",
      "\\\\atopfrac", "\\\\bracefrac", "\\\\brackfrac",
    ],
    2,
    allowed_in_argument=true,
    handler=standard_genfrac_handler,
  )
}

///|
fn standard_genfrac_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let config = standard_genfrac_config(context.func_name)
  let node = GenFrac(
    mode=context.mode,
    numer=require_function_arg(args, 0, context.func_name),
    denom=require_function_arg(args, 1, context.func_name),
    continued=config.continued,
    has_bar_line=config.has_bar_line,
    bar_size=None,
    left_delim=config.left_delim,
    right_delim=config.right_delim,
  )
  wrap_genfrac_style(node, config.style)
}

///|
fn infix_replacement(func_name : String) -> String raise ParseFailure {
  match func_name {
    "\\over" => "\\frac"
    "\\choose" => "\\binom"
    "\\atop" => "\\\\atopfrac"
    "\\brace" => "\\\\bracefrac"
    "\\brack" => "\\\\brackfrac"
    _ =>
      raise InternalInvariant(
        message="Unrecognized infix genfrac command: " + func_name,
      )
  }
}

///|
fn infix_genfrac_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\over", "\\choose", "\\atop", "\\brace", "\\brack"],
    0,
    infix=true,
    handler=infix_genfrac_handler,
  )
}

///|
fn infix_genfrac_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Infix(
    mode=context.mode,
    replace_with=infix_replacement(context.func_name),
    size=None,
    token=context.token,
  )
}

///|
fn delimiter_from_argument(arg : ParseNode, family : AtomFamily) -> String? {
  match (normalize_argument(arg), family) {
    (Atom(family=Mopen, text~, ..), Mopen) =>
      if text == "." {
        None
      } else {
        Some(text)
      }
    (Atom(family=Mclose, text~, ..), Mclose) =>
      if text == "." {
        None
      } else {
        Some(text)
      }
    _ => None
  }
}

///|
fn genfrac_style(arg : ParseNode) -> StyleLevel? raise ParseFailure {
  let first = match arg {
    OrdGroup(body=[], ..) => return None
    OrdGroup(body=[node, ..], ..) => node
    node => node
  }
  let text = match first {
    TextOrd(text~, ..) => text
    _ =>
      raise InternalInvariant(
        message="\\genfrac style argument did not contain a textord",
      )
  }
  match text {
    "0" => Some(DisplayStyle)
    "1" => Some(TextStyle)
    "2" => Some(ScriptStyle)
    "3" => Some(ScriptScriptStyle)
    _ => None
  }
}

///|
fn general_genfrac_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\genfrac"],
    6,
    arg_types=[MathArg, MathArg, SizeArg, TextArg, MathArg, MathArg],
    allowed_in_argument=true,
    handler=general_genfrac_handler,
  )
}

///|
fn general_genfrac_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let left = require_function_arg(args, 0, context.func_name)
  let right = require_function_arg(args, 1, context.func_name)
  let bar = require_function_arg(args, 2, context.func_name)
  let style_arg = require_function_arg(args, 3, context.func_name)
  let numer = require_function_arg(args, 4, context.func_name)
  let denom = require_function_arg(args, 5, context.func_name)
  guard bar is Size(value~, is_blank~, ..) else {
    raise InternalInvariant(message="\\genfrac bar argument was not a size")
  }
  let has_bar_line = is_blank || value.number > 0.0
  let bar_size = if is_blank { None } else { Some(value) }
  let node = GenFrac(
    mode=context.mode,
    numer~,
    denom~,
    continued=false,
    has_bar_line~,
    bar_size~,
    left_delim=delimiter_from_argument(left, Mopen),
    right_delim=delimiter_from_argument(right, Mclose),
  )
  wrap_genfrac_style(node, genfrac_style(style_arg))
}

///|
fn above_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\above"],
    1,
    arg_types=[SizeArg],
    infix=true,
    handler=above_handler,
  )
}

///|
fn above_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  guard require_function_arg(args, 0, context.func_name) is Size(value~, ..) else {
    raise InternalInvariant(message="\\above argument was not a size")
  }
  Infix(
    mode=context.mode,
    replace_with="\\\\abovefrac",
    size=Some(value),
    token=context.token,
  )
}

///|
fn abovefrac_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\\\abovefrac"],
    3,
    arg_types=[MathArg, SizeArg, MathArg],
    handler=abovefrac_handler,
  )
}

///|
fn abovefrac_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let numer = require_function_arg(args, 0, context.func_name)
  let infix = require_function_arg(args, 1, context.func_name)
  let denom = require_function_arg(args, 2, context.func_name)
  guard infix is Infix(size=Some(bar_size), ..) else {
    raise InternalInvariant(message="\\\\abovefrac expected an infix size")
  }
  GenFrac(
    mode=context.mode,
    numer~,
    denom~,
    continued=false,
    has_bar_line=bar_size.number > 0.0,
    bar_size=Some(bar_size),
    left_delim=None,
    right_delim=None,
  )
}
