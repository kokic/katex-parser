///|
priv struct MClassCommandSpec {
  name : String
  mclass : AtomFamily
}

///|
let mclass_commands : Array[MClassCommandSpec] = [
  { name: "\\mathord", mclass: Mord },
  { name: "\\mathbin", mclass: Mbin },
  { name: "\\mathrel", mclass: Mrel },
  { name: "\\mathopen", mclass: Mopen },
  { name: "\\mathclose", mclass: Mclose },
  { name: "\\mathpunct", mclass: Mpunct },
  { name: "\\mathinner", mclass: Minner },
]

///|
fn command_mclass(func_name : String) -> AtomFamily raise ParseFailure {
  for command in mclass_commands {
    guard command.name == func_name else { continue }
    return command.mclass
  }
  raise InternalInvariant(message="Unknown math class command: " + func_name)
}

///|
fn mclass_spec() -> FunctionSpec {
  FunctionSpec::make(
    mclass_commands.map(command => command.name),
    1,
    primitive=true,
    handler=mclass_handler,
  )
}

///|
fn mclass_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let body = require_function_arg(args, 0, context.func_name)
  MClass(
    mode=context.mode,
    mclass=command_mclass(context.func_name),
    body=ord_argument(body),
    is_character_box=is_character_box(body),
  )
}

///|
fn binrel_spec() -> FunctionSpec {
  FunctionSpec::make(["\\@binrel"], 2, handler=binrel_handler)
}

///|
fn binrel_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let class_arg = require_function_arg(args, 0, context.func_name)
  let body = require_function_arg(args, 1, context.func_name)
  MClass(
    mode=context.mode,
    mclass=binrel_class(class_arg),
    body=ord_argument(body),
    is_character_box=is_character_box(body),
  )
}

///|
fn stackrel_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\stackrel", "\\overset", "\\underset"],
    2,
    handler=stackrel_handler,
  )
}

///|
fn stackrel_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let shifted = require_function_arg(args, 0, context.func_name)
  let base_arg = require_function_arg(args, 1, context.func_name)
  let mclass = if context.func_name == "\\stackrel" {
    Mrel
  } else {
    binrel_class(base_arg)
  }
  let base = Op(
    mode=base_arg.mode(),
    limits=true,
    always_handle_sup_sub=true,
    parent_is_sup_sub=false,
    suppress_base_shift=context.func_name != "\\stackrel",
    content=BodyOperator(ord_argument(base_arg)),
  )
  let stacked = if context.func_name == "\\underset" {
    SupSub(mode=shifted.mode(), base=Some(base), sup=None, sub=Some(shifted))
  } else {
    SupSub(mode=shifted.mode(), base=Some(base), sup=Some(shifted), sub=None)
  }
  MClass(
    mode=context.mode,
    mclass~,
    body=[stacked],
    is_character_box=is_character_box(stacked),
  )
}
