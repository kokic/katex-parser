///|
fn require_function_arg(
  args : Array[ParseNode],
  index : Int,
  func_name : String,
) -> ParseNode raise ParseFailure {
  guard args.get(index) is Some(arg) else {
    raise InternalInvariant(
      message="Missing argument \{index} for " + func_name,
    )
  }
  arg
}

///|
fn ord_argument(arg : ParseNode) -> Array[ParseNode] {
  match arg {
    OrdGroup(body~, ..) => body
    _ => [arg]
  }
}

///|
fn normalize_argument(arg : ParseNode) -> ParseNode {
  match arg {
    OrdGroup(body=[only], ..) => only
    _ => arg
  }
}
