///|
fn delimiter_size(func_name : String) -> Int raise ParseFailure {
  match func_name {
    "\\bigl" | "\\bigr" | "\\bigm" | "\\big" => 1
    "\\Bigl" | "\\Bigr" | "\\Bigm" | "\\Big" => 2
    "\\biggl" | "\\biggr" | "\\biggm" | "\\bigg" => 3
    "\\Biggl" | "\\Biggr" | "\\Biggm" | "\\Bigg" => 4
    _ =>
      raise InternalInvariant(
        message="Unknown delimiter sizing function " + func_name,
      )
  }
}

///|
fn delimiter_mclass(func_name : String) -> AtomFamily raise ParseFailure {
  match func_name {
    "\\bigl" | "\\Bigl" | "\\biggl" | "\\Biggl" => Mopen
    "\\bigr" | "\\Bigr" | "\\biggr" | "\\Biggr" => Mclose
    "\\bigm" | "\\Bigm" | "\\biggm" | "\\Biggm" => Mrel
    "\\big" | "\\Big" | "\\bigg" | "\\Bigg" => Mord
    _ =>
      raise InternalInvariant(
        message="Unknown delimiter sizing function " + func_name,
      )
  }
}

///|
fn delimiter_text(node : ParseNode) -> String? {
  match node {
    Atom(text~, ..) => Some(text)
    MathOrd(text~, ..) => Some(text)
    TextOrd(text~, ..) => Some(text)
    Spacing(text~, ..) => Some(text)
    AccentToken(text~, ..) => Some(text)
    OperatorToken(text~, ..) => Some(text)
    _ => None
  }
}

///|
fn is_delimiter(text : String) -> Bool {
  match text {
    "("
    | "\\lparen"
    | ")"
    | "\\rparen"
    | "["
    | "\\lbrack"
    | "]"
    | "\\rbrack"
    | "\\{"
    | "\\lbrace"
    | "\\}"
    | "\\rbrace"
    | "\\lfloor"
    | "\\rfloor"
    | "⌊"
    | "⌋"
    | "\\lceil"
    | "\\rceil"
    | "⌈"
    | "⌉"
    | "<"
    | ">"
    | "\\langle"
    | "⟨"
    | "\\rangle"
    | "⟩"
    | "\\lt"
    | "\\gt"
    | "\\lvert"
    | "\\rvert"
    | "\\lVert"
    | "\\rVert"
    | "\\lgroup"
    | "\\rgroup"
    | "⟮"
    | "⟯"
    | "\\lmoustache"
    | "\\rmoustache"
    | "⎰"
    | "⎱"
    | "/"
    | "\\backslash"
    | "|"
    | "\\vert"
    | "\\|"
    | "\\Vert"
    | "\\uparrow"
    | "\\Uparrow"
    | "\\downarrow"
    | "\\Downarrow"
    | "\\updownarrow"
    | "\\Updownarrow"
    | "." => true
    _ => false
  }
}

///|
fn checked_delimiter(
  node : ParseNode,
  func_name : String,
) -> String raise ParseFailure {
  match delimiter_text(node) {
    Some(text) if is_delimiter(text) => text
    Some(text) =>
      raise InvalidArgument(
        message="Invalid delimiter '" + text + "' after '" + func_name + "'",
        loc=None,
      )
    None =>
      raise InvalidArgument(
        message="Invalid delimiter type after '" + func_name + "'",
        loc=None,
      )
  }
}

///|
fn delim_sizing_spec() -> FunctionSpec {
  FunctionSpec::make(
    [
      "\\bigl", "\\Bigl", "\\biggl", "\\Biggl", "\\bigr", "\\Bigr", "\\biggr", "\\Biggr",
      "\\bigm", "\\Bigm", "\\biggm", "\\Biggm", "\\big", "\\Big", "\\bigg", "\\Bigg",
    ],
    1,
    arg_types=[PrimitiveArg],
    handler=delim_sizing_handler,
  )
}

///|
fn delim_sizing_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  DelimSizing(
    mode=context.mode,
    size=delimiter_size(context.func_name),
    mclass=delimiter_mclass(context.func_name),
    delim=checked_delimiter(
      require_function_arg(args, 0, context.func_name),
      context.func_name,
    ),
  )
}

///|
fn left_right_closing_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\right"],
    1,
    arg_types=[PrimitiveArg],
    primitive=true,
    handler=left_right_closing_handler,
  )
}

///|
fn left_right_closing_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  LeftRightRight(
    mode=context.mode,
    delim=checked_delimiter(
      require_function_arg(args, 0, context.func_name),
      context.func_name,
    ),
    color=(context.current_color)(),
  )
}

///|
fn left_right_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\left"],
    1,
    arg_types=[PrimitiveArg],
    primitive=true,
    handler=left_right_handler,
  )
}

///|
fn left_right_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  (context.parse_left_right)(
    checked_delimiter(
      require_function_arg(args, 0, context.func_name),
      context.func_name,
    ),
  )
}

///|
fn middle_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\middle"],
    1,
    arg_types=[PrimitiveArg],
    primitive=true,
    handler=middle_handler,
  )
}

///|
fn middle_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let delim = checked_delimiter(
    require_function_arg(args, 0, context.func_name),
    context.func_name,
  )
  if !(context.in_left_right)() {
    raise InvalidArgument(message="\\middle without preceding \\left", loc=None)
  }
  Middle(mode=context.mode, delim~)
}
