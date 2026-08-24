///|
/// Canonical form of the normalized expression parsed from `source`.
fn canonical(source : String) -> String raise @katex.ParseFailure {
  let nodes = @katex.parse(source)
  let expr = @eval.lower_expr(nodes, @eval.EvalOptions::make()).unwrap()
  let expr = @eval.normalize(expr, @eval.EvalOptions::make()).unwrap()
  expr.to_canonical_string()
}

///|
fn eval_render(source : String) -> String raise @katex.ParseFailure {
  @unicode.render(@facade.parse(source))
}

///|
test "eval basic arithmetic" {
  @test.assert_eq(eval_render("\\eval{1+3}"), "4")
  @test.assert_eq(eval_render("\\eval{2+3*4}"), "14")
  @test.assert_eq(eval_render("\\eval{2^3}"), "8")
  @test.assert_eq(eval_render("\\eval{2(3+x)}"), "2x + 6")
  @test.assert_eq(eval_render("\\eval{2x+3x}"), "5x")
  @test.assert_eq(eval_render("\\eval{x+x*x}"), "x² + x")
  @test.assert_eq(eval_render("\\eval{(x+1)^2}"), "x² + 2x + 1")
  @test.assert_eq(eval_render("\\eval{\\frac{6}{3}}"), "2")
  @test.assert_eq(eval_render("\\eval{x-3}"), "x − 3")
  @test.assert_eq(eval_render("\\eval{-2x}"), "−2x")
}

///|
test "eval canonical forms" {
  @test.assert_eq(canonical("1+3"), "N4")
  @test.assert_eq(canonical("x+x"), "M(N2, Sx)")
  @test.assert_eq(canonical("x*x"), "P(Sx, 2)")
  @test.assert_eq(canonical("x+x*x"), "A(P(Sx, 2), Sx)")
  @test.assert_eq(canonical("(x+1)*(x+1)"), "A(P(Sx, 2), M(N2, Sx), N1)")
  @test.assert_eq(canonical("2x+3x"), "M(N5, Sx)")
  @test.assert_eq(canonical("0*x"), "N0")
  @test.assert_eq(canonical("x*1"), "Sx")
  @test.assert_eq(canonical("x^0"), "N1")
  @test.assert_eq(canonical("x-x"), "N0")
  @test.assert_eq(canonical("x+2x"), "M(N3, Sx)")
  @test.assert_eq(canonical("\\alpha+\\alpha"), "M(N2, S\\alpha)")
  @test.assert_eq(canonical("\\frac{4}{2}"), "N2")
  @test.assert_eq(canonical("2^{10}"), "N1024")
}

///|
test "eval decimal literals are rejected" {
  let raised = try {
    let _ = @facade.parse("\\eval{2.14}")
    false
  } catch {
    _ => true
  }
  @test.assert_eq(raised, true)
}

///|
test "eval integer overflow is rejected" {
  let raised = try {
    let _ = @facade.parse("\\eval{2^{31}}")
    false
  } catch {
    _ => true
  }
  @test.assert_eq(raised, true)
}

///|
test "eval macro scope" {
  @test.assert_eq(eval_render("\\def\\y{x}\\eval{x+\\y}"), "2x")
  @test.assert_eq(eval_render("\\gdef\\y{x}\\eval{2\\y}"), "2x")
  @test.assert_eq(eval_render("\\edef\\y{1+2}\\eval{\\y+1}"), "4")
  @test.assert_eq(eval_render("\\eval{\\eval{1+2}+3}"), "6")
}

///|
test "eval group cleanup" {
  let raised = try {
    let _ = @facade.parse("{\\def\\y{x}}\\eval{\\y}")
    false
  } catch {
    _ => true
  }
  @test.assert_eq(raised, true)
}

///|
test "eval division by zero raises" {
  let raised = try {
    let _ = @facade.parse("\\eval{\\frac{1}{0}}")
    false
  } catch {
    _ => true
  }
  @test.assert_eq(raised, true)
}

///|
test "eval strict mode rejects unsupported nodes" {
  let nodes = @katex.parse("1+\\sqrt{2}")
  let strict = @eval.EvalOptions::make(mode=Strict)
  let partial = @eval.EvalOptions::make(mode=Partial)
  @test.assert_eq(@eval.lower_expr(nodes, strict) is Err(_), true)
  let lowered = @eval.lower_expr(nodes, partial).unwrap()
  let normalized = @eval.normalize(lowered, partial).unwrap()
  let constant_last = match normalized {
    @eval.EvalExpr::Add(children) =>
      children.length() == 2 &&
      (match children[1] {
        @eval.EvalExpr::Number(_) => true
        _ => false
      })
    _ => false
  }
  @test.assert_eq(constant_last, true)
}

///|
test "eval normalize is idempotent" {
  for source in ["1+3", "x+x*x", "(x+1)^2", "2x+3x", "x-x"] {
    let nodes = @katex.parse(source)
    let options = @eval.EvalOptions::make()
    let expr = @eval.lower_expr(nodes, options).unwrap()
    let once = @eval.normalize(expr, options).unwrap()
    let twice = @eval.normalize(once, options).unwrap()
    @test.assert_eq(twice, once)
  }
}

///|
test "eval display mode" {
  let settings = @katex.Settings::make(display_mode=true)
  @test.assert_eq(
    @unicode.render(@facade.parse("\\eval{1+3}", settings~)),
    "4",
  )
}

///|
test "eval partial mode keeps residuals separate" {
  let nodes = @katex.parse("1+2+\\sin(y)")
  let options = @eval.EvalOptions::make()
  let expr = @eval.lower_expr(nodes, options).unwrap()
  let normalized = @eval.normalize(expr, options).unwrap()
  let is_sum_of_two = match normalized {
    @eval.EvalExpr::Add(children) => children.length() == 2
    _ => false
  }
  @test.assert_eq(is_sum_of_two, true)
}
