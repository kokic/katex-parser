///|
fn decimal_char_code(text : String) -> Int? {
  let mut value = 0
  let mut saw_digit = false
  for code in text {
    guard code >= '0' && code <= '9' else { break }
    saw_digit = true
    let digit = code.to_int() - ('0' : Char).to_int()
    value = if value > (2147483647 - digit) / 10 {
      2147483647
    } else {
      value * 10 + digit
    }
  }
  if saw_digit {
    Some(value)
  } else {
    None
  }
}

///|
fn char_argument_text(
  arg : ParseNode,
  func_name : String,
) -> String raise ParseFailure {
  guard arg is OrdGroup(body~, ..) else {
    raise InternalInvariant(message="Expected group argument for " + func_name)
  }
  let builder = StringBuilder()
  for node in body {
    guard node is TextOrd(text~, ..) else {
      raise InternalInvariant(
        message="Expected text character for " + func_name,
      )
    }
    builder.write_string(text)
  }
  builder.to_string()
}

///|
fn char_spec() -> FunctionSpec {
  FunctionSpec::make(["\\@char"], 1, allowed_in_text=true, handler=char_handler)
}

///|
fn char_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let number = char_argument_text(
    require_function_arg(args, 0, context.func_name),
    context.func_name,
  )
  guard decimal_char_code(number) is Some(code) else {
    raise InvalidArgument(
      message="\\@char has non-numeric argument " + number,
      loc=None,
    )
  }
  guard code >= 0 && code < 0x10ffff else {
    raise InvalidArgument(
      message="\\@char with invalid code point " + number,
      loc=None,
    )
  }
  guard code.to_char() is Some(character) else {
    raise InternalInvariant(
      message="Unable to convert validated character code",
    )
  }
  TextOrd(mode=context.mode, loc=None, text=String::from_array([character]))
}
