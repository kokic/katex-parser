///|
pub(all) enum EvalFailureKind {
  UnsupportedNode
  InvalidNumber
  DivisionByZero
  InvalidPower
  IntegerOverflow
  ExpressionTooLarge
  TooManyRewriteSteps
} derive(Eq, @debug.Debug)

///|
pub(all) struct EvalDiagnostic {
  kind : EvalFailureKind
  loc : @katex_parser.SourceLocation?
} derive(Eq, @debug.Debug)

///|
pub fn EvalDiagnostic::make(
  kind : EvalFailureKind,
  loc? : @katex_parser.SourceLocation? = None,
) -> EvalDiagnostic {
  { kind, loc }
}

///|
pub fn EvalDiagnostic::message(self : EvalDiagnostic) -> String {
  match self.kind {
    UnsupportedNode => "unsupported construct in \\eval"
    InvalidNumber => "invalid number in \\eval"
    DivisionByZero => "division by zero in \\eval"
    InvalidPower => "invalid exponent in \\eval"
    IntegerOverflow => "integer overflow in \\eval"
    ExpressionTooLarge => "expression too large in \\eval"
    TooManyRewriteSteps => "expression too complex to evaluate in \\eval"
  }
}

///|
/// How unsupported subtrees are treated during lowering.
pub(all) enum EvalMode {
  /// Unsupported subtrees abort with an `UnsupportedNode` diagnostic.
  Strict
  /// Unsupported subtrees are kept as opaque `Residual` nodes.
  Partial
} derive(Eq, @debug.Debug)

///|
pub(all) struct EvalOptions {
  mode : EvalMode
  max_terms : Int
  max_rewrite_steps : Int
}

///|
pub fn EvalOptions::make(
  mode? : EvalMode = Partial,
  max_terms? : Int = 256,
  max_rewrite_steps? : Int = 256,
) -> EvalOptions {
  { mode, max_terms, max_rewrite_steps }
}
