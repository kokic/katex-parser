///|
#warnings("-unused_constructor")
priv enum ArgType {
  ColorArg
  SizeArg
  UrlArg
  RawArg
  OriginalArg
  HboxArg
  PrimitiveArg
  MathArg
  TextArg
}

///|
priv struct FunctionContext {
  func_name : String
  mode : Mode
  token : Token?
  break_on_token_text : String?
  set_macro : (String, MacroDefinition?) -> Unit
  report_nonstrict : (String, String) -> Unit raise ParseFailure
  is_trusted : (TrustContext) -> Bool
  unsupported_command : (String) -> ParseNode
  parse_optional_size : () -> Measurement? raise ParseFailure
  display_mode : Bool
  use_strict_behavior : (String, String) -> Bool
  current_color : () -> String? raise ParseFailure
  in_left_right : () -> Bool
  parse_expression : (Bool, String?) -> Array[ParseNode] raise ParseFailure
  parse_math_mode : (String) -> Array[ParseNode] raise ParseFailure
  parse_left_right : (String) -> ParseNode raise ParseFailure
  pop_token : () -> Token raise ParseFailure
  future_token : () -> Token raise ParseFailure
  push_token : (Token) -> Unit
  consume_spaces : () -> Unit raise ParseFailure
  consume_macro_arg : () -> Array[Token] raise ParseFailure
  expand_tokens : (Array[Token]) -> Array[Token] raise ParseFailure
  get_macro : (String) -> MacroDefinition?
  set_macro_definition : (String, MacroDefinition, Bool) -> Unit
  is_expandable : (String) -> Bool
  parse_prefixed_function : (String) -> ParseNode raise ParseFailure
  parse_environment : (String) -> ParseNode raise ParseFailure
}

///|
type FunctionHandler = (FunctionContext, Array[ParseNode], Array[ParseNode?]) -> ParseNode raise ParseFailure

///|
#warnings("-unused_field")
priv struct FunctionSpec {
  names : Array[String]
  num_args : Int
  num_optional_args : Int
  arg_types : Array[ArgType]
  allowed_in_argument : Bool
  allowed_in_text : Bool
  allowed_in_math : Bool
  infix : Bool
  primitive : Bool
  primitive_after_missing_optional : Int?
  handler : FunctionHandler?
}

///|
fn FunctionSpec::make(
  names : Array[String],
  num_args : Int,
  num_optional_args? : Int = 0,
  arg_types? : Array[ArgType] = [],
  allowed_in_argument? : Bool = false,
  allowed_in_text? : Bool = false,
  allowed_in_math? : Bool = true,
  infix? : Bool = false,
  primitive? : Bool = false,
  primitive_after_missing_optional? : Int,
  handler? : FunctionHandler,
) -> FunctionSpec {
  {
    names,
    num_args,
    num_optional_args,
    arg_types,
    allowed_in_argument,
    allowed_in_text,
    allowed_in_math,
    infix,
    primitive,
    primitive_after_missing_optional,
    handler,
  }
}

///|
fn FunctionSpec::is_expandable(self : FunctionSpec) -> Bool {
  !self.primitive
}

///|
priv struct FunctionRegistry {
  entries : Map[String, FunctionSpec]
}

///|
fn FunctionRegistry::make() -> FunctionRegistry {
  { entries: Map([]) }
}

///|
fn FunctionRegistry::register(
  self : FunctionRegistry,
  spec : FunctionSpec,
) -> Unit {
  for name in spec.names {
    self.entries[name] = spec
  }
}

///|
fn FunctionRegistry::get(
  self : FunctionRegistry,
  name : String,
) -> FunctionSpec? {
  self.entries.get(name)
}

///|
fn verb_spec() -> FunctionSpec {
  FunctionSpec::make(["\\verb"], 0, allowed_in_text=true, handler=verb_handler)
}

///|
fn verb_handler(
  context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let loc = match context.token {
    Some(token) => token.loc
    None => None
  }
  raise InvalidArgument(
    message="\\verb ended by end of line instead of matching delimiter",
    loc~,
  )
}

///|
fn relax_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\relax"],
    0,
    allowed_in_argument=true,
    allowed_in_text=true,
    handler=(context, args, opt_args) => relax_handler(context, args, opt_args),
  )
}

///|
fn relax_handler(
  _context : FunctionContext,
  _args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode {
  Internal(mode=_context.mode)
}

///|
let builtin_function_specs : Array[FunctionSpec] = [
  verb_spec(),
  relax_spec(),
  sqrt_spec(),
  standard_genfrac_spec(),
  infix_genfrac_spec(),
  general_genfrac_spec(),
  above_spec(),
  abovefrac_spec(),
  text_spec(),
  textcolor_spec(),
  color_spec(),
  styling_spec(),
  font_spec(),
  boldsymbol_spec(),
  old_font_spec(),
  mclass_spec(),
  binrel_spec(),
  stackrel_spec(),
  big_operator_spec(),
  mathop_spec(),
  named_operator_spec(),
  limited_named_operator_spec(),
  integral_operator_spec(),
  operatorname_spec(),
  overline_spec(),
  underline_spec(),
  smash_spec(),
  phantom_spec(),
  vphantom_spec(),
  pmb_spec(),
  vcenter_spec(),
  rule_spec(),
  raisebox_spec(),
  hbox_spec(),
  lap_spec(),
  mathchoice_spec(),
  sizing_spec(),
  char_spec(),
  horiz_brace_spec(),
  x_arrow_spec(),
  accent_under_spec(),
  accent_spec(),
  text_accent_spec(),
  kern_spec(),
  colorbox_spec(),
  fcolorbox_spec(),
  fbox_spec(),
  cancel_spec(),
  sout_spec(),
  angl_spec(),
  href_spec(),
  url_spec(),
  html_spec(),
  cr_spec(),
  macro_prefix_spec(),
  definition_spec(),
  let_spec(),
  futurelet_spec(),
  includegraphics_spec(),
  begin_end_spec(),
  hline_spec(),
  cd_internal_spec(),
  cd_parent_spec(),
  html_mathml_spec(),
  math_mode_spec(),
  math_closing_spec(),
  delim_sizing_spec(),
  left_right_closing_spec(),
  left_right_spec(),
  middle_spec(),
]

///|
fn build_builtin_function_registry() -> FunctionRegistry {
  let registry = FunctionRegistry::make()
  for spec in builtin_function_specs {
    registry.register(spec)
  }
  registry
}

///|
let builtin_function_registry : FunctionRegistry = build_builtin_function_registry()

///|
fn lookup_function(name : String) -> FunctionSpec? {
  builtin_function_registry.get(name)
}
