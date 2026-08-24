///|
pub extend SymbolKey with @debug.Debug::{to_repr}

///|
pub extend SymbolKey with Eq::{not_equal, equal}

///|
pub extend SymbolKey with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MonomialFactor with @debug.Debug::{to_repr}

///|
pub extend MonomialFactor with Eq::{not_equal, equal}

///|
pub extend Monomial with @debug.Debug::{to_repr}

///|
pub extend Monomial with Eq::{not_equal, equal}

///|
pub extend Term with @debug.Debug::{to_repr}

///|
pub extend Term with Eq::{not_equal, equal}

///|
pub extend Polynomial with @debug.Debug::{to_repr}

///|
pub extend Polynomial with Eq::{not_equal, equal}

///|
pub extend EvalExpr with @debug.Debug::{to_repr}

///|
pub extend EvalExpr with Eq::{not_equal, equal}

///|
pub extend EvalFailureKind with @debug.Debug::{to_repr}

///|
pub extend EvalFailureKind with Eq::{not_equal, equal}

///|
pub extend EvalDiagnostic with @debug.Debug::{to_repr}

///|
pub extend EvalDiagnostic with Eq::{not_equal, equal}

///|
pub extend EvalMode with @debug.Debug::{to_repr}

///|
pub extend EvalMode with Eq::{not_equal, equal}
