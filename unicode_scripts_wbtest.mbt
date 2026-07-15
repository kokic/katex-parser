///|
fn unicode_script_kind_name(kind : UnicodeScriptKind) -> String {
  match kind {
    UnicodeSubscript => "sub"
    UnicodeSuperscript => "sup"
  }
}

///|
fn unicode_script_fingerprint() -> (Int64, Int64) {
  let modulus : Int64 = 2147483647
  let mut sum : Int64 = 0
  let mut squares : Int64 = 0
  for name, script in unicode_scripts {
    let entry = "\{name.length()}:\{name}:\{script.replacement.length()}:\{script.replacement}:\{unicode_script_kind_name(script.kind)}"
    let hash = test_string_fingerprint(entry)
    sum = (sum + hash) % modulus
    squares = (squares + hash * hash) % modulus
  }
  (sum, squares)
}

///|
test "Unicode script registry matches official data" {
  assert_eq(unicode_scripts.length(), 102)
  assert_eq(unicode_script_fingerprint(), (97154155, 1443092342))
  assert_true(
    lookup_unicode_script("₂")
    is Some({ replacement: "2", kind: UnicodeSubscript }),
  )
  assert_true(
    lookup_unicode_script("ᵝ")
    is Some({ replacement: "β", kind: UnicodeSuperscript }),
  )
}

///|
test "consecutive Unicode superscripts form one parsed ordgroup" {
  match parse("x²³") {
    [
      SupSub(
        mode=Math,
        base=Some(MathOrd(mode=Math, text="x", ..)),
        sup=Some(
          OrdGroup(
            mode=Math,
            loc=None,
            body=[
              TextOrd(mode=Math, loc=None, text="2"),
              TextOrd(mode=Math, loc=None, text="3"),
            ],
            semisimple=false
          )
        ),
        sub=None
      ),
    ] => ()
    _ => fail("unexpected Unicode superscript AST")
  }
}

///|
test "Unicode subscript and superscript runs remain separate" {
  match parse("x₂ₙ³") {
    [
      SupSub(
        base=Some(MathOrd(text="x", ..)),
        sup=Some(OrdGroup(body=[TextOrd(text="3", ..)], ..)),
        sub=Some(
          OrdGroup(body=[TextOrd(text="2", ..), MathOrd(text="n", ..)], ..)
        ),
        ..
      ),
    ] => ()
    _ => fail("unexpected mixed Unicode script AST")
  }
}

///|
test "Unicode script body uses normal parser symbol families" {
  match parse("x⁺ᵝ₍₎") {
    [
      SupSub(
        sup=Some(
          OrdGroup(
            body=[Atom(family=Mbin, text="+", ..), MathOrd(text="β", ..)],
            ..
          )
        ),
        sub=Some(
          OrdGroup(
            body=[
              Atom(family=Mopen, text="(", ..),
              Atom(family=Mclose, text=")", ..),
            ],
            ..
          )
        ),
        ..
      ),
    ] => ()
    _ => fail("unexpected parsed Unicode script body")
  }
}

///|
test "Unicode superscript follows KaTeX replacement semantics" {
  match parse("x^2³") {
    [SupSub(sup=Some(OrdGroup(body=[TextOrd(text="3", ..)], ..)), ..)] => ()
    _ => fail("Unicode superscript should replace an existing superscript")
  }
}

///|
test "subparse restores the main token stream" {
  match parse("x²+y") {
    [
      SupSub(sup=Some(OrdGroup(body=[TextOrd(text="2", ..)], ..)), ..),
      Atom(family=Mbin, text="+", ..),
      MathOrd(text="y", ..),
    ] => ()
    _ => fail("main token stream was not restored after Unicode script")
  }
}
