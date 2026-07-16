///|
priv struct OperatorCommandSpec {
  name : String
  canonical_name : String
}

///|
let big_operator_commands : Array[OperatorCommandSpec] = [
  { name: "\\coprod", canonical_name: "\\coprod" },
  { name: "\\bigvee", canonical_name: "\\bigvee" },
  { name: "\\bigwedge", canonical_name: "\\bigwedge" },
  { name: "\\biguplus", canonical_name: "\\biguplus" },
  { name: "\\bigcap", canonical_name: "\\bigcap" },
  { name: "\\bigcup", canonical_name: "\\bigcup" },
  { name: "\\intop", canonical_name: "\\intop" },
  { name: "\\prod", canonical_name: "\\prod" },
  { name: "\\sum", canonical_name: "\\sum" },
  { name: "\\bigotimes", canonical_name: "\\bigotimes" },
  { name: "\\bigoplus", canonical_name: "\\bigoplus" },
  { name: "\\bigodot", canonical_name: "\\bigodot" },
  { name: "\\bigsqcup", canonical_name: "\\bigsqcup" },
  { name: "\\smallint", canonical_name: "\\smallint" },
  { name: "∏", canonical_name: "\\prod" },
  { name: "∐", canonical_name: "\\coprod" },
  { name: "∑", canonical_name: "\\sum" },
  { name: "⋀", canonical_name: "\\bigwedge" },
  { name: "⋁", canonical_name: "\\bigvee" },
  { name: "⋂", canonical_name: "\\bigcap" },
  { name: "⋃", canonical_name: "\\bigcup" },
  { name: "⨀", canonical_name: "\\bigodot" },
  { name: "⨁", canonical_name: "\\bigoplus" },
  { name: "⨂", canonical_name: "\\bigotimes" },
  { name: "⨄", canonical_name: "\\biguplus" },
  { name: "⨆", canonical_name: "\\bigsqcup" },
]

///|
let integral_operator_commands : Array[OperatorCommandSpec] = [
  { name: "\\int", canonical_name: "\\int" },
  { name: "\\iint", canonical_name: "\\iint" },
  { name: "\\iiint", canonical_name: "\\iiint" },
  { name: "\\oint", canonical_name: "\\oint" },
  { name: "\\oiint", canonical_name: "\\oiint" },
  { name: "\\oiiint", canonical_name: "\\oiiint" },
  { name: "∫", canonical_name: "\\int" },
  { name: "∬", canonical_name: "\\iint" },
  { name: "∭", canonical_name: "\\iiint" },
  { name: "∮", canonical_name: "\\oint" },
  { name: "∯", canonical_name: "\\oiint" },
  { name: "∰", canonical_name: "\\oiiint" },
]

///|
let named_operator_commands : Array[String] = [
  "\\arcsin", "\\arccos", "\\arctan", "\\arctg", "\\arcctg", "\\arg", "\\ch", "\\cos",
  "\\cosec", "\\cosh", "\\cot", "\\cotg", "\\coth", "\\csc", "\\ctg", "\\cth", "\\deg",
  "\\dim", "\\exp", "\\hom", "\\ker", "\\lg", "\\ln", "\\log", "\\sec", "\\sin",
  "\\sinh", "\\sh", "\\tan", "\\tanh", "\\tg", "\\th",
]

///|
let limited_named_operator_commands : Array[String] = [
  "\\det", "\\gcd", "\\inf", "\\lim", "\\max", "\\min", "\\Pr", "\\sup",
]

///|
fn operator_names(commands : Array[OperatorCommandSpec]) -> Array[String] {
  commands.map(command => command.name)
}

///|
fn canonical_operator_name(
  commands : Array[OperatorCommandSpec],
  func_name : String,
) -> String raise ParseFailure {
  for command in commands {
    guard command.name == func_name else { continue }
    return command.canonical_name
  }
  raise InternalInvariant(message="Unknown operator command: " + func_name)
}

///|
fn symbol_operator(mode : Mode, limits : Bool, name : String) -> ParseNode {
  Op(
    mode~,
    limits~,
    always_handle_sup_sub=false,
    parent_is_sup_sub=false,
    suppress_base_shift=false,
    content=SymbolOperator(name),
  )
}

///|
fn named_operator(mode : Mode, limits : Bool, name : String) -> ParseNode {
  Op(
    mode~,
    limits~,
    always_handle_sup_sub=false,
    parent_is_sup_sub=false,
    suppress_base_shift=false,
    content=NamedOperator(name),
  )
}

///|
fn big_operator_spec() -> FunctionSpec {
  FunctionSpec::make(
    operator_names(big_operator_commands),
    0,
    handler=big_operator_handler,
  )
}

///|
fn big_operator_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  symbol_operator(
    context.mode,
    true,
    canonical_operator_name(big_operator_commands, context.func_name),
  )
}

///|
fn mathop_spec() -> FunctionSpec {
  FunctionSpec::make(["\\mathop"], 1, primitive=true, handler=mathop_handler)
}

///|
fn mathop_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Op(
    mode=context.mode,
    limits=false,
    always_handle_sup_sub=false,
    parent_is_sup_sub=false,
    suppress_base_shift=false,
    content=BodyOperator(
      ord_argument(require_function_arg(args, 0, context.func_name)),
    ),
  )
}

///|
fn named_operator_spec() -> FunctionSpec {
  FunctionSpec::make(named_operator_commands, 0, handler=(
    context,
    args,
    opt_args,
  ) => named_operator_handler(context, args, opt_args))
}

///|
fn named_operator_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode {
  named_operator(context.mode, false, context.func_name)
}

///|
fn limited_named_operator_spec() -> FunctionSpec {
  FunctionSpec::make(limited_named_operator_commands, 0, handler=(
    context,
    args,
    opt_args,
  ) => limited_named_operator_handler(context, args, opt_args))
}

///|
fn limited_named_operator_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode {
  named_operator(context.mode, true, context.func_name)
}

///|
fn integral_operator_spec() -> FunctionSpec {
  FunctionSpec::make(
    operator_names(integral_operator_commands),
    0,
    allowed_in_argument=true,
    handler=integral_operator_handler,
  )
}

///|
fn integral_operator_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  symbol_operator(
    context.mode,
    false,
    canonical_operator_name(integral_operator_commands, context.func_name),
  )
}
