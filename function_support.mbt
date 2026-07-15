///|
fn require_function_arg(
  args : Array[ParseNode],
  index : Int,
  func_name : String,
) -> ParseNode raise ParseFailure {
  match args.get(index) {
    Some(arg) => arg
    None =>
      raise InternalInvariant(
        message="Missing argument \{index} for " + func_name,
      )
  }
}

///|
fn ord_argument(arg : ParseNode) -> Array[ParseNode] {
  match arg {
    OrdGroup(body~, ..) => body
    _ => [arg]
  }
}
