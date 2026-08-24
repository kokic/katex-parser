///|
/// The `\eval` function spec: evaluates its argument in the current macro
/// scope and substitutes the computed result as a normal parse node.
pub fn eval_spec() -> @katex_parser.FunctionSpec {
  @katex_parser.FunctionSpec::make(
    ["\\eval"],
    1,
    allowed_in_argument=true,
    handler=eval_handler,
  )
}

///|
fn eval_handler(
  _context : @katex_parser.FunctionContext,
  args : Array[@katex_parser.ParseNode],
  _opt_args : Array[@katex_parser.ParseNode?],
) -> @katex_parser.ParseNode raise @katex_parser.ParseFailure {
  let options = EvalOptions::make()
  guard args.length() == 1 else {
    raise @katex_parser.ParseFailure::InternalInvariant(
      message="\\eval expects exactly one argument",
    )
  }
  let (body, rewrap) = strip_wrappers(args[0])
  match lower_expr(body, options) {
    Err(diag) => raise eval_failure(diag)
    Ok(expr) =>
      match normalize(expr, options) {
        Err(diag) => raise eval_failure(diag)
        Ok(expr) =>
          match render(expr) {
            Err(diag) => raise eval_failure(diag)
            Ok(node) => rewrap(node)
          }
      }
  }
}

///|
fn eval_failure(diag : EvalDiagnostic) -> @katex_parser.ParseFailure {
  InvalidArgument(message=diag.message(), loc=diag.loc)
}

///|
/// Peels off outer layout wrappers (groups, styling, color) so the inner
/// expression can be computed, and re-applies them to the rendered result.
fn strip_wrappers(
  node : @katex_parser.ParseNode,
) -> (
  Array[@katex_parser.ParseNode],
  (@katex_parser.ParseNode) -> @katex_parser.ParseNode,
) {
  match node {
    @katex_parser.ParseNode::OrdGroup(mode~, loc~, body=original_body, ..) =>
      (
        original_body,
        inner => {
          @katex_parser.ParseNode::OrdGroup(
            mode~,
            loc~,
            body=[inner],
            semisimple=false,
          )
        },
      )
    @katex_parser.ParseNode::Styling(mode~, body~, style~, reset_font~) =>
      match body {
        [inner] => {
          let (inner_body, rewrap) = strip_wrappers(inner)
          (
            inner_body,
            result => {
              @katex_parser.ParseNode::Styling(
                mode~,
                body=[rewrap(result)],
                style~,
                reset_font~,
              )
            },
          )
        }
        _ => ([node], inner => inner)
      }
    @katex_parser.ParseNode::Color(mode~, color~, body~) =>
      match body {
        [inner] => {
          let (inner_body, rewrap) = strip_wrappers(inner)
          (
            inner_body,
            result => {
              @katex_parser.ParseNode::Color(mode~, color~, body=[
                rewrap(result),
              ])
            },
          )
        }
        _ => ([node], inner => inner)
      }
    _ => ([node], inner => inner)
  }
}
