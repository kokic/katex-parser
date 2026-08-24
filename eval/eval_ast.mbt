///|
/// A symbolic variable. The key is the canonical TeX spelling of the symbol
/// as it appears in the parsed AST, e.g. `"x"` or `"\\alpha"`.
pub(all) struct SymbolKey {
  text : String
} derive(Eq, Compare, @debug.Debug)

///|
pub fn SymbolKey::make(text : String) -> SymbolKey {
  SymbolKey::{ text, }
}

///|
/// A factor of a monomial: a symbolic variable, or an opaque expression that
/// can! participate in symbolic arithmetic (e.g. a residual subtree).
pub(all) enum MonomialFactor {
  SymbolFactor(SymbolKey)
  OpaqueFactor(EvalExpr)
} derive(Eq, @debug.Debug)

///|
/// An ordered product of factors with non-negative integer exponents.
/// Canonical form: factors sorted, equal factors merged.
pub(all) struct Monomial {
  factors : Array[(MonomialFactor, Int)]
} derive(Eq, @debug.Debug)

///|
pub(all) struct Term {
  coefficient : Int
  monomial : Monomial
} derive(Eq, @debug.Debug)

///|
/// A polynomial as an ordered sum of terms, sorted by graded lexicographic
/// order (total degree descending, then factor order ascending).
pub(all) struct Polynomial {
  terms : Array[Term]
} derive(Eq, @debug.Debug)

///|
/// A computed mathematical expression. Canonicalized by `normalize`:
/// addition/multiplication are flattened, like terms are combined, and
/// children are sorted by total degree. Numbers are exact `Int` values.
pub(all) enum EvalExpr {
  Number(Int)
  Symbol(SymbolKey)
  Add(Array[EvalExpr])
  Mul(Array[EvalExpr])
  Pow(EvalExpr, Int)
  Div(EvalExpr, EvalExpr)
  Residual(@katex.ParseNode)
} derive(Eq, @debug.Debug)

///|
/// Canonical serialization of an expression, used for structured test
/// assertions and as a stable key for opaque terms. Two structurally equal
/// expressions produce equal strings.
pub fn EvalExpr::to_canonical_string(self : EvalExpr) -> String {
  match self {
    Number(value) => "N\{value}"
    Symbol(symbol) => "S\{symbol.text}"
    Add(children) => join_parts("A", children)
    Mul(children) => join_parts("M", children)
    Pow(base, exp) => "P(\{base.to_canonical_string()}, \{exp})"
    Div(numer, denom) =>
      "D(\{numer.to_canonical_string()}, \{denom.to_canonical_string()})"
    Residual(node) => "R\{@debug.to_string(node)}"
  }
}

///|
fn Monomial::degree(self : Monomial) -> Int {
  let mut total = 0
  for item in self.factors {
    let (_, exp) = item
    total = total + exp
  }
  total
}

///|
fn Monomial::to_canonical_string(self : Monomial) -> String {
  let parts : Array[String] = []
  for item in self.factors {
    let (factor, exp) = item
    parts.push("\{factor.to_canonical_string()}^\{exp}")
  }
  parts.join("|")
}

///|
fn MonomialFactor::to_canonical_string(self : MonomialFactor) -> String {
  match self {
    SymbolFactor(symbol) => "s\{symbol.text}"
    OpaqueFactor(expr) => "o\{expr.to_canonical_string()}"
  }
}

///|
fn join_parts(name : String, children : Array[EvalExpr]) -> String {
  let inner : Array[String] = []
  for child in children {
    inner.push(child.to_canonical_string())
  }
  "\{name}(\{inner.join(", ")})"
}
