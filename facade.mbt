///|
/// Parses a TeX math expression with `\eval` registered: `\eval{...}` is
/// computed in the current macro scope and replaced by the result.
pub fn parse(
  input : String,
  settings? : @katex.Settings = Default::default(),
) -> Array[@katex.ParseNode] raise @katex.ParseFailure {
  @katex.parse(input, settings~, extra_specs=[@eval.eval_spec()])
}

///|
/// Lowers a parsed math group into a computed expression.
pub fn lower_expr(
  nodes : Array[@katex.ParseNode],
  options? : @eval.EvalOptions = @eval.EvalOptions::make(),
) -> Result[@eval.EvalExpr, @eval.EvalDiagnostic] {
  @eval.lower_expr(nodes, options)
}

///|
/// Normalizes an expression to canonical form.
pub fn normalize_expr(
  expr : @eval.EvalExpr,
  options? : @eval.EvalOptions = @eval.EvalOptions::make(),
) -> Result[@eval.EvalExpr, @eval.EvalDiagnostic] {
  @eval.normalize(expr, options)
}

///|
/// Renders a computed expression back into a `ParseNode`.
pub fn render_expr(
  expr : @eval.EvalExpr,
) -> Result[@katex.ParseNode, @eval.EvalDiagnostic] {
  @eval.render(expr)
}

///|
/// Full pipeline: lower, normalize, and render a parsed math group.
pub fn evaluate_expr(
  nodes : Array[@katex.ParseNode],
  options? : @eval.EvalOptions = @eval.EvalOptions::make(),
) -> Result[@katex.ParseNode, @eval.EvalDiagnostic] {
  let expr = match @eval.lower_expr(nodes, options) {
    Err(e) => return Err(e)
    Ok(expr) => expr
  }
  let expr = match @eval.normalize(expr, options) {
    Err(e) => return Err(e)
    Ok(expr) => expr
  }
  @eval.render(expr)
}

///|
pub fn supported_codepoint(code : Int) -> Bool {
  @katex.supported_codepoint(code)
}

///|
pub fn unicode_font_character(font : String, char : String) -> String? {
  @katex.unicode_font_character(font, char)
}

///|
pub fn unicode_script_character(
  kind : @katex.UnicodeScriptKind,
  char : String,
) -> String? {
  @katex.unicode_script_character(kind, char)
}

///|
pub fn unicode_symbol(symbol : String) -> String? {
  @katex.unicode_symbol(symbol)
}
