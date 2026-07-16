///|
priv struct FontCommandSpec {
  name : String
  font : String
}

///|
let font_commands : Array[FontCommandSpec] = [
  { name: "\\mathrm", font: "mathrm" },
  { name: "\\mathit", font: "mathit" },
  { name: "\\mathbf", font: "mathbf" },
  { name: "\\mathnormal", font: "mathnormal" },
  { name: "\\mathsfit", font: "mathsfit" },
  { name: "\\mathbb", font: "mathbb" },
  { name: "\\mathcal", font: "mathcal" },
  { name: "\\mathfrak", font: "mathfrak" },
  { name: "\\mathscr", font: "mathscr" },
  { name: "\\mathsf", font: "mathsf" },
  { name: "\\mathtt", font: "mathtt" },
  { name: "\\Bbb", font: "mathbb" },
  { name: "\\bold", font: "mathbf" },
  { name: "\\frak", font: "mathfrak" },
]

///|
let old_font_commands : Array[FontCommandSpec] = [
  { name: "\\rm", font: "mathrm" },
  { name: "\\sf", font: "mathsf" },
  { name: "\\tt", font: "mathtt" },
  { name: "\\bf", font: "mathbf" },
  { name: "\\it", font: "mathit" },
  { name: "\\cal", font: "mathcal" },
]

///|
fn command_font(
  commands : Array[FontCommandSpec],
  func_name : String,
) -> String raise ParseFailure {
  for command in commands {
    guard command.name == func_name else { continue }
    return command.font
  }
  raise InternalInvariant(message="Unknown font command: " + func_name)
}

///|
fn font_spec() -> FunctionSpec {
  FunctionSpec::make(
    font_commands.map(command => command.name),
    1,
    allowed_in_argument=true,
    handler=font_handler,
  )
}

///|
fn font_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  Font(
    mode=context.mode,
    font=command_font(font_commands, context.func_name),
    body=normalize_argument(require_function_arg(args, 0, context.func_name)),
  )
}

///|
fn boldsymbol_spec() -> FunctionSpec {
  FunctionSpec::make(["\\boldsymbol", "\\bm"], 1, handler=boldsymbol_handler)
}

///|
fn boldsymbol_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let body = require_function_arg(args, 0, context.func_name)
  MClass(
    mode=context.mode,
    mclass=binrel_class(body),
    body=[Font(mode=context.mode, font="boldsymbol", body~)],
    is_character_box=is_character_box(body),
  )
}

///|
fn old_font_spec() -> FunctionSpec {
  FunctionSpec::make(
    old_font_commands.map(command => command.name),
    0,
    allowed_in_text=true,
    handler=old_font_handler,
  )
}

///|
fn old_font_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let body = (context.parse_expression)(true, context.break_on_token_text)
  Font(
    mode=context.mode,
    font=command_font(old_font_commands, context.func_name),
    body=OrdGroup(mode=context.mode, loc=None, body~, semisimple=false),
  )
}
