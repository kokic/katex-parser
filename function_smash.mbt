///|
fn smash_flags(arg : ParseNode?) -> (Bool, Bool) raise ParseFailure {
  guard arg is Some(OrdGroup(body~, ..)) else { (true, true) }
  let mut smash_height = false
  let mut smash_depth = false
  for node in body {
    let text = match node {
      MathOrd(text~, ..) | TextOrd(text~, ..) | Atom(text~, ..) => text
      _ => raise InternalInvariant(message="Expected symbol in \\smash option")
    }
    if text == "t" {
      smash_height = true
    } else if text == "b" {
      smash_depth = true
    } else {
      return (false, false)
    }
  }
  (smash_height, smash_depth)
}

///|
fn smash_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\smash"],
    1,
    num_optional_args=1,
    allowed_in_text=true,
    handler=smash_handler,
  )
}

///|
fn smash_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let (smash_height, smash_depth) = smash_flags(opt_args.get(0).unwrap_or(None))
  Smash(
    mode=context.mode,
    body=require_function_arg(args, 0, context.func_name),
    smash_height~,
    smash_depth~,
  )
}
