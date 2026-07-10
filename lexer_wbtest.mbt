///|
test "Lexer::lex basic control word and symbols" {
  let lexer = Lexer::make("\\frac x+1")
  let t0 = lexer.lex().unwrap()
  let t1 = lexer.lex().unwrap()
  let t2 = lexer.lex().unwrap()
  let t3 = lexer.lex().unwrap()
  let t4 = lexer.lex().unwrap()
  debug_inspect(
    [t0.text, t1.text, t2.text, t3.text, t4.text],
    content="[\"\\\\frac\", \"x\", \"+\", \"1\", \"EOF\"]",
  )
}

///|
test "Lexer::lex skips comments" {
  let lexer = Lexer::make("x% comment\ny")
  let t0 = lexer.lex().unwrap()
  let t1 = lexer.lex().unwrap()
  let t2 = lexer.lex().unwrap()
  debug_inspect([t0.text, t1.text, t2.text], content="[\"x\", \"y\", \"EOF\"]")
}

///|
test "Lexer::lex keeps non-BMP unicode scalar as one token" {
  let lexer = Lexer::make("𝛼x")
  let t0 = lexer.lex().unwrap()
  let t1 = lexer.lex().unwrap()
  let t2 = lexer.lex().unwrap()
  debug_inspect(
    [t0.text, t1.text, t2.text],
    content="[\"𝛼\", \"x\", \"EOF\"]",
  )
  debug_inspect(t0.loc, content="Some({ input: \"𝛼x\", start: 0, end: 2 })")
}
