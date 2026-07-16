///|
fn kern_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\kern", "\\mkern", "\\hskip", "\\mskip"],
    1,
    arg_types=[SizeArg],
    primitive=true,
    allowed_in_text=true,
    handler=kern_handler,
  )
}

///|
fn kern_dimension(
  args : Array[ParseNode],
  func_name : String,
) -> Measurement raise ParseFailure {
  guard require_function_arg(args, 0, func_name) is Size(value~, ..) else {
    raise InternalInvariant(message="Expected size argument for " + func_name)
  }
  value
}

///|
fn is_math_spacing_function(func_name : String) -> Bool {
  func_name == "\\mkern" || func_name == "\\mskip"
}

///|
fn kern_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let dimension = kern_dimension(args, context.func_name)
  let uses_mu = dimension.unit == "mu"
  if is_math_spacing_function(context.func_name) {
    if !uses_mu {
      (context.report_nonstrict)(
        "mathVsTextUnits",
        "LaTeX's " +
        context.func_name +
        " supports only mu units, not " +
        dimension.unit +
        " units",
      )
    }
    if context.mode != Math {
      (context.report_nonstrict)(
        "mathVsTextUnits",
        "LaTeX's " + context.func_name + " works only in math mode",
      )
    }
  } else if uses_mu {
    (context.report_nonstrict)(
      "mathVsTextUnits",
      "LaTeX's " + context.func_name + " doesn't support mu units",
    )
  }
  Kern(mode=context.mode, dimension~)
}
