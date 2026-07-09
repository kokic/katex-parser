///|
test "Lexer::lex basic control word and symbols" {
  let lexer = Lexer::make("\\frac x+1", Settings::default())
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
  let lexer = Lexer::make("x% comment\ny", Settings::default())
  let t0 = lexer.lex().unwrap()
  let t1 = lexer.lex().unwrap()
  let t2 = lexer.lex().unwrap()
  debug_inspect([t0.text, t1.text, t2.text], content="[\"x\", \"y\", \"EOF\"]")
}
