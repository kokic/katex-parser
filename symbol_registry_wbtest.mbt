///|
fn assert_symbol_group(
  mode : Mode,
  name : String,
  expected : SymbolGroup,
) -> Unit raise {
  match lookup_symbol(mode, name) {
    Some({ group }) =>
      match (group, expected) {
        (AccentTokenGroup, AccentTokenGroup)
        | (BinaryGroup, BinaryGroup)
        | (CloseGroup, CloseGroup)
        | (InnerGroup, InnerGroup)
        | (MathOrdGroup, MathOrdGroup)
        | (OperatorTokenGroup, OperatorTokenGroup)
        | (OpenGroup, OpenGroup)
        | (PunctuationGroup, PunctuationGroup)
        | (RelationGroup, RelationGroup)
        | (SpacingGroup, SpacingGroup)
        | (TextOrdGroup, TextOrdGroup) => ()
        _ => fail("unexpected symbol group for " + name)
      }
    None => fail("missing symbol " + name)
  }
}

///|
fn symbol_group_name(group : SymbolGroup) -> String {
  match group {
    AccentTokenGroup => "accent-token"
    BinaryGroup => "bin"
    CloseGroup => "close"
    InnerGroup => "inner"
    MathOrdGroup => "mathord"
    OperatorTokenGroup => "op-token"
    OpenGroup => "open"
    PunctuationGroup => "punct"
    RelationGroup => "rel"
    SpacingGroup => "spacing"
    TextOrdGroup => "textord"
  }
}

///|
fn symbol_registry_fingerprint() -> (Int64, Int64) {
  let modulus : Int64 = 2147483647
  let mut sum : Int64 = 0
  let mut squares : Int64 = 0
  for name, spec in builtin_symbols.math {
    let entry = "math:\{name.length()}:\{name}:\{symbol_group_name(spec.group)}"
    let hash = test_string_fingerprint(entry)
    sum = (sum + hash) % modulus
    squares = (squares + hash * hash) % modulus
  }
  for name, spec in builtin_symbols.text {
    let entry = "text:\{name.length()}:\{name}:\{symbol_group_name(spec.group)}"
    let hash = test_string_fingerprint(entry)
    sum = (sum + hash) % modulus
    squares = (squares + hash * hash) % modulus
  }
  (sum, squares)
}

///|
test "symbol registry matches official mode totals" {
  assert_eq(builtin_symbols.math.length(), 1488)
  assert_eq(builtin_symbols.text.length(), 750)
  assert_eq(symbol_registry_fingerprint(), (1476257044, 1295843928))
}

///|
test "symbol registry preserves modes groups and accepted Unicode aliases" {
  assert_symbol_group(Math, "\\acute", AccentTokenGroup)
  assert_symbol_group(Math, "\\pm", BinaryGroup)
  assert_symbol_group(Math, "\\rangle", CloseGroup)
  assert_symbol_group(Math, "\\ldots", InnerGroup)
  assert_symbol_group(Math, "\\alpha", MathOrdGroup)
  assert_symbol_group(Math, "\\sum", OperatorTokenGroup)
  assert_symbol_group(Math, "\\langle", OpenGroup)
  assert_symbol_group(Math, ",", PunctuationGroup)
  assert_symbol_group(Math, "\\equiv", RelationGroup)
  assert_symbol_group(Math, "\\space", SpacingGroup)
  assert_symbol_group(Math, "1", TextOrdGroup)
  assert_symbol_group(Math, "≡", RelationGroup)
  assert_symbol_group(Math, "𝐀", MathOrdGroup)
  assert_symbol_group(Text, "𝐀", TextOrdGroup)
  assert_symbol_group(Math, "𝕜", MathOrdGroup)
  assert_symbol_group(Text, "𝕜", TextOrdGroup)
  assert_true(lookup_symbol(Text, "\\equiv") is None)
}

///|
test "symbol registry is the source of MacroExpander command status" {
  let expander = MacroExpander::make("", Settings::default())
  assert_true(expander.is_defined("\\lambda"))
  assert_false(expander.is_expandable("\\lambda"))
  assert_true(expander.is_defined("≡"))
}

///|
test "symbol groups map to their exact AST node kinds" {
  let loc : SourceLocation? = None
  assert_true(
    make_symbol_node(
      Math,
      "\\acute",
      loc,
      lookup_symbol(Math, "\\acute").unwrap(),
    )
    is AccentToken(mode=Math, loc=None, text="\\acute"),
  )
  assert_true(
    make_symbol_node(Math, "\\sum", loc, lookup_symbol(Math, "\\sum").unwrap())
    is OperatorToken(mode=Math, loc=None, text="\\sum"),
  )
  assert_true(
    make_symbol_node(
      Math,
      "\\space",
      loc,
      lookup_symbol(Math, "\\space").unwrap(),
    )
    is Spacing(mode=Math, loc=None, text="\\space"),
  )
  assert_true(
    make_symbol_node(Math, "(", loc, lookup_symbol(Math, "(").unwrap())
    is Atom(mode=Math, loc=None, family=Mopen, text="("),
  )
}

///|
test "parser recognizes named and Unicode symbols through the registry" {
  match parse("\\alpha≡\\beta") {
    [
      MathOrd(mode=Math, text="\\alpha", ..),
      Atom(mode=Math, family=Mrel, text="≡", ..),
      MathOrd(mode=Math, text="\\beta", ..),
    ] => ()
    _ => fail("unexpected symbol parse result")
  }
}

///|
test "parser treats unregistered non-ASCII symbols as text-mode textord" {
  match parse("😀") {
    [TextOrd(mode=Text, text="😀", ..)] => ()
    _ => fail("unexpected unknown Unicode parse result")
  }
}
