///|
fn unicode_decomposition_fingerprint() -> (Int64, Int64) {
  let modulus : Int64 = 2147483647
  let mut sum : Int64 = 0
  let mut squares : Int64 = 0
  for name, decomposition in unicode_symbol_decompositions {
    let entry = "\{name.length()}:\{name}:\{decomposition.length()}:\{decomposition}"
    let hash = test_string_fingerprint(entry)
    sum = (sum + hash) % modulus
    squares = (squares + hash * hash) % modulus
  }
  (sum, squares)
}

///|
fn assert_acute_ast(input : String) -> Unit raise {
  match parse(input) {
    Ok(
      [
        Accent(
          mode=Math,
          label="\\acute",
          is_stretchy=false,
          is_shifty=true,
          base=MathOrd(mode=Math, text="e", ..),
          ..
        ),
      ]
    ) => ()
    _ => fail("unexpected acute AST for " + input)
  }
}

///|
fn assert_double_accent_ast(input : String) -> Unit raise {
  match parse(input) {
    Ok(
      [
        Accent(
          mode=Math,
          label="\\acute",
          base=Accent(
            mode=Math,
            label="\\mathring",
            base=MathOrd(mode=Math, text="a", ..),
            ..
          ),
          ..
        ),
      ]
    ) => ()
    _ => fail("unexpected double-accent AST for " + input)
  }
}

///|
test "Unicode decomposition table matches official generated data" {
  assert_eq(unicode_symbol_decompositions.length(), 344)
  assert_eq(unicode_decomposition_fingerprint(), (353611021, 819069324))
  assert_eq(normalize_unicode_symbol(Math, "é"), "é")
  assert_eq(normalize_unicode_symbol(Math, "ǻ"), "ǻ")
  assert_eq(normalize_unicode_symbol(Math, "ά"), "ά")
}

///|
test "Unicode accent lookup matches math and text commands" {
  let accents : Array[(String, String, String)] = [
    ("́", "\\acute", "\\'"),
    ("̀", "\\grave", "\\`"),
    ("̈", "\\ddot", "\\\""),
    ("̃", "\\tilde", "\\~"),
    ("̄", "\\bar", "\\="),
    ("̆", "\\breve", "\\u"),
    ("̌", "\\check", "\\v"),
    ("̂", "\\hat", "\\^"),
    ("̇", "\\dot", "\\."),
    ("̊", "\\mathring", "\\r"),
    ("̋", "\\H", "\\H"),
    ("̧", "\\c", "\\c"),
  ]
  for item in accents {
    let (accent, math, text) = item
    assert_eq(unicode_accent_command(Math, accent), Some(math))
    assert_eq(unicode_accent_command(Text, accent), Some(text))
  }
  assert_eq(unicode_accent_command(Math, "̅"), None)
}

///|
test "precomposed and decomposed accents produce the same AST shape" {
  assert_acute_ast("é")
  assert_acute_ast("é")
}

///|
test "multiple combining accents preserve KaTeX nesting order" {
  assert_double_accent_ast("ǻ")
  assert_double_accent_ast("ǻ")
}

///|
test "combining accents use dotless i and j bases" {
  match parse("îj́") {
    Ok(
      [
        Accent(label="\\hat", base=TextOrd(mode=Math, text="ı", ..), ..),
        Accent(label="\\acute", base=TextOrd(mode=Math, text="ȷ", ..), ..),
      ]
    ) => ()
    _ => fail("expected dotless accent bases")
  }
}

///|
test "unknown combining accent is rejected" {
  match parse("a̅") {
    Err(InvalidArgument(message~, ..)) =>
      assert_eq(message, "Unknown accent ' ̅'")
    _ => fail("expected unknown accent error")
  }
}
