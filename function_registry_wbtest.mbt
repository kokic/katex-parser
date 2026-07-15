///|
fn require_function(
  registry : FunctionRegistry,
  name : String,
) -> FunctionSpec raise {
  match registry.get(name) {
    Some(spec) => spec
    None => fail("missing function registration: " + name)
  }
}

///|
test "builtin function registry preserves KaTeX parser defaults" {
  assert_eq(builtin_function_specs.length(), 8)
  assert_eq(builtin_function_registry.entries.length(), 21)
  let verb = require_function(builtin_function_registry, "\\verb")
  assert_eq(verb.names, ["\\verb"])
  assert_eq(verb.num_args, 0)
  assert_eq(verb.num_optional_args, 0)
  assert_true(verb.arg_types.is_empty())
  assert_false(verb.allowed_in_argument)
  assert_true(verb.allowed_in_text)
  assert_true(verb.allowed_in_math)
  assert_false(verb.infix)
  assert_false(verb.primitive)
  assert_eq(verb.primitive_after_missing_optional, None)
  assert_true(verb.handler is Some(_))

  let relax = require_function(builtin_function_registry, "\\relax")
  assert_true(relax.allowed_in_argument)
  assert_true(relax.allowed_in_text)
  assert_true(relax.allowed_in_math)
  assert_true(relax.handler is Some(_))
}

///|
test "FunctionRegistry aliases share a spec and later definitions win" {
  let registry = FunctionRegistry::make()
  let first = FunctionSpec::make(["\\first", "\\alias"], 1, primitive=true)
  registry.register(first)
  assert_eq(require_function(registry, "\\first").names, first.names)
  assert_eq(require_function(registry, "\\alias").names, first.names)
  assert_false(require_function(registry, "\\alias").is_expandable())

  let replacement = FunctionSpec::make(["\\alias"], 2, allowed_in_text=true)
  registry.register(replacement)
  assert_eq(require_function(registry, "\\first").num_args, 1)
  assert_eq(require_function(registry, "\\alias").num_args, 2)
  assert_true(require_function(registry, "\\alias").allowed_in_text)
  assert_true(require_function(registry, "\\alias").is_expandable())
}

///|
test "function registry drives MacroExpander command classification" {
  assert_true(default_command_status("\\relax") is ExternalExpandable)
  assert_true(default_command_status("\\verb") is ExternalExpandable)
  assert_true(default_command_status("\\alpha") is ExternalUnexpandable)
  assert_true(default_command_status("\\missing") is ExternalUndefined)
}

///|
test "FunctionContext preserves handler metadata" {
  let parser = Parser::make("\\relax", Settings::default())
  let token = parser.fetch()
  parser.consume()
  let context : FunctionContext = {
    func_name: token.text,
    parser,
    token: Some(token),
    break_on_token_text: Some("}"),
  }
  assert_eq(context.func_name, "\\relax")
  assert_eq(context.token, Some(token))
  assert_eq(context.break_on_token_text, Some("}"))
  assert_true(context.parser.next_token is None)
}

///|
test "Parser::call_function distinguishes internal output and missing handlers" {
  let parser = Parser::make("", Settings::default())
  assert_true(
    parser.call_function("\\relax", [], [], None, Some("}"))
    is Internal(mode=Math),
  )
  match
    capture_parse_result(() => {
      parser.call_function("\\missing", [], [], None, None)
    }) {
    Err(MissingFunctionHandler(func_name="\\missing", loc=None)) => ()
    _ => fail("expected missing function handler")
  }
}

///|
test "internal function nodes are filtered and skipped in script arguments" {
  assert_true(parse("\\relax x") is [MathOrd(text="x", ..)])
  assert_true(
    parse("x^\\relax 2") is [SupSub(sup=Some(TextOrd(text="2", ..)), ..)],
  )
}
