///|
/// Normalizes an expression to canonical form: flattens `Add`/`Mul`, folds
/// numeric constants, expands powers and distributes products, combines like
/// terms, and sorts terms by total degree descending. The result is idempotent
/// and structurally stable.
pub fn normalize(
  expr : EvalExpr,
  options : EvalOptions,
) -> Result[EvalExpr, EvalDiagnostic] {
  let mut current = expr
  let mut steps = 0
  while steps < options.max_rewrite_steps {
    match normalize_once(current, options) {
      Err(e) => return Err(e)
      Ok(next) => {
        if next == current {
          return Ok(current)
        }
        current = next
        steps = steps + 1
      }
    }
  }
  Err(EvalDiagnostic::make(TooManyRewriteSteps))
}

///|
fn normalize_once(
  expr : EvalExpr,
  options : EvalOptions,
) -> Result[EvalExpr, EvalDiagnostic] {
  match expr {
    Number(_) | Symbol(_) | Residual(_) => Ok(expr)
    Add(children) => {
      let flat = flatten_add(children)
      if flat.length() == 1 {
        return normalize_once(flat[0], options)
      }
      match combine_children(flat, options) {
        Err(e) => Err(e)
        Ok(poly) => Ok(poly_to_expr(poly))
      }
    }
    Mul(children) => {
      let flat = flatten_mul(children)
      match flat.length() {
        0 => Ok(Number(1))
        1 => normalize_once(flat[0], options)
        _ => {
          let mut acc : Polynomial = { terms: [unit_term()] }
          for child in flat {
            match normalize_once(child, options) {
              Err(e) => return Err(e)
              Ok(normalized) =>
                match
                  poly_mul(acc, expr_to_poly(normalized), options.max_terms) {
                  Err(e) => return Err(e)
                  Ok(product) => acc = product
                }
            }
          }
          Ok(poly_to_expr(acc))
        }
      }
    }
    Pow(base, exp) => normalize_power(base, exp, options)
    Div(numer, denom) => normalize_div(numer, denom, options)
  }
}

///|
fn flatten_add(children : Array[EvalExpr]) -> Array[EvalExpr] {
  let result : Array[EvalExpr] = []
  for child in children {
    match child {
      Add(grandchildren) => result.append(grandchildren)
      _ => result.push(child)
    }
  }
  result
}

///|
fn flatten_mul(children : Array[EvalExpr]) -> Array[EvalExpr] {
  let result : Array[EvalExpr] = []
  for child in children {
    match child {
      Mul(grandchildren) => result.append(grandchildren)
      _ => result.push(child)
    }
  }
  result
}

///|
/// Normalizes each child, converts it to a polynomial, and sums the results.
fn combine_children(
  children : Array[EvalExpr],
  options : EvalOptions,
) -> Result[Polynomial, EvalDiagnostic] {
  let mut result : Polynomial = { terms: [] }
  for child in children {
    match normalize_once(child, options) {
      Err(e) => return Err(e)
      Ok(normalized) =>
        match poly_add(result, expr_to_poly(normalized), options.max_terms) {
          Err(e) => return Err(e)
          Ok(sum) => result = sum
        }
    }
  }
  Ok(result)
}

///|
/// Evaluates a power. Integer bases fold exactly (bounded by `max_terms`);
/// polynomial bases are expanded. Negative integer powers of integers are
/// not representable exactly and stay as `Pow`.
fn normalize_power(
  base : EvalExpr,
  exp : Int,
  options : EvalOptions,
) -> Result[EvalExpr, EvalDiagnostic] {
  let base = match normalize_once(base, options) {
    Err(e) => return Err(e)
    Ok(base) => base
  }
  if exp == 0 {
    match base {
      Number(0) => Err(EvalDiagnostic::make(InvalidPower))
      _ => Ok(Number(1))
    }
  } else if exp == 1 {
    Ok(base)
  } else {
    match base {
      Number(value) => power_int(value, exp)
      Pow(inner, m) => {
        if exp > 1 << 30 || m > 1 << 30 {
          return Err(EvalDiagnostic::make(ExpressionTooLarge))
        }
        normalize_power(inner, m * exp, options)
      }
      Add(_) | Mul(_) => {
        if exp > 16 {
          return Err(EvalDiagnostic::make(ExpressionTooLarge))
        }
        match poly_pow(expr_to_poly(base), exp, options) {
          Err(e) => Err(e)
          Ok(poly) => Ok(poly_to_expr(poly))
        }
      }
      _ => Ok(Pow(base, exp))
    }
  }
}

///|
fn power_int(base : Int, exp : Int) -> Result[EvalExpr, EvalDiagnostic] {
  if exp < 0 {
    // e.g. 2^-1: not representable as an integer; keep the power.
    return Ok(Pow(Number(base), exp))
  }
  guard exp <= 4096 else {
    return Err(EvalDiagnostic::make(ExpressionTooLarge))
  }
  let mut result = 1
  let mut i = 0
  while i < exp {
    match checked_int_mul(result, base) {
      None => return Err(EvalDiagnostic::make(IntegerOverflow))
      Some(product) => result = product
    }
    i = i + 1
  }
  Ok(Number(result))
}

///|
/// Normalizes a division: exact integer divisions fold; otherwise the `Div`
/// node is kept (fractions are not representable yet).
fn normalize_div(
  numer : EvalExpr,
  denom : EvalExpr,
  options : EvalOptions,
) -> Result[EvalExpr, EvalDiagnostic] {
  let numer = match normalize_once(numer, options) {
    Err(e) => return Err(e)
    Ok(numer) => numer
  }
  let denom = match normalize_once(denom, options) {
    Err(e) => return Err(e)
    Ok(denom) => denom
  }
  match denom {
    Number(0) => Err(EvalDiagnostic::make(DivisionByZero))
    Number(divisor) =>
      match numer {
        Number(value) =>
          if value % divisor == 0 {
            Ok(Number(value / divisor))
          } else {
            Ok(Div(numer, denom))
          }
        _ => {
          let poly = expr_to_poly(numer)
          let mut exact = true
          for term in poly.terms {
            if term.coefficient % divisor != 0 {
              exact = false
            }
          }
          if !exact {
            return Ok(Div(numer, denom))
          }
          let scaled : Array[Term] = []
          for term in poly.terms {
            scaled.push({
              coefficient: term.coefficient / divisor,
              monomial: term.monomial,
            })
          }
          let scaled = scaled.filter(fn(term) { term.coefficient != 0 })
          Ok(poly_to_expr({ terms: sort_terms(scaled) }))
        }
      }
    _ => Ok(Div(numer, denom))
  }
}

///|
fn expr_to_poly(expr : EvalExpr) -> Polynomial {
  match expr {
    Number(value) =>
      { terms: [{ coefficient: value, monomial: Monomial::empty() }] }
    Symbol(symbol) =>
      { terms: [{ coefficient: 1, monomial: Monomial::symbol(symbol) }] }
    Pow(Symbol(symbol), exp) =>
      {
        terms: [{ coefficient: 1, monomial: Monomial::symbol_pow(symbol, exp) }],
      }
    Pow(_, _) => opaque_term(expr)
    Add(children) => {
      let mut result : Polynomial = { terms: [] }
      for child in children {
        let sum = poly_add(result, expr_to_poly(child), 0x7FFF_FFFF).unwrap()
        result = sum
      }
      result
    }
    Mul(children) => {
      let mut result : Polynomial = { terms: [unit_term()] }
      for child in children {
        let product = poly_mul(result, expr_to_poly(child), 0x7FFF_FFFF).unwrap()
        result = product
      }
      result
    }
    Div(_, _) | Residual(_) => opaque_term(expr)
  }
}

///|
fn opaque_term(expr : EvalExpr) -> Polynomial {
  { terms: [{ coefficient: 1, monomial: Monomial::opaque_factor(expr) }] }
}

///|
fn unit_term() -> Term {
  { coefficient: 1, monomial: Monomial::empty() }
}

///|
fn Monomial::empty() -> Monomial {
  { factors: [] }
}

///|
fn Monomial::symbol(symbol : SymbolKey) -> Monomial {
  { factors: [(SymbolFactor(symbol), 1)] }
}

///|
fn Monomial::symbol_pow(symbol : SymbolKey, exp : Int) -> Monomial {
  { factors: [(SymbolFactor(symbol), exp)] }
}

///|
fn Monomial::opaque_factor(expr : EvalExpr) -> Monomial {
  { factors: [(OpaqueFactor(expr), 1)] }
}

///|
fn poly_to_expr(poly : Polynomial) -> EvalExpr {
  match poly.terms.length() {
    0 => Number(0)
    1 => term_to_expr(poly.terms[0])
    _ => {
      let exprs : Array[EvalExpr] = []
      for term in poly.terms {
        exprs.push(term_to_expr(term))
      }
      Add(exprs)
    }
  }
}

///|
fn term_to_expr(term : Term) -> EvalExpr {
  let factors : Array[EvalExpr] = []
  for item in term.monomial.factors {
    let (factor, exp) = item
    let base = match factor {
      SymbolFactor(symbol) => Symbol(symbol)
      OpaqueFactor(expr) => expr
    }
    factors.push(if exp == 1 { base } else { Pow(base, exp) })
  }
  match factors.length() {
    0 => Number(term.coefficient)
    _ => {
      let product = match factors.length() {
        1 => factors[0]
        _ => Mul(factors)
      }
      if term.coefficient == 1 {
        product
      } else {
        Mul([Number(term.coefficient), product])
      }
    }
  }
}

///|
fn poly_add(
  a : Polynomial,
  b : Polynomial,
  max_terms : Int,
) -> Result[Polynomial, EvalDiagnostic] {
  let terms = a.terms.copy()
  for term in b.terms {
    match add_or_merge(terms, term) {
      Err(e) => return Err(e)
      Ok(_) => ()
    }
    guard terms.length() <= max_terms else {
      return Err(EvalDiagnostic::make(ExpressionTooLarge))
    }
  }
  let terms = terms.filter(fn(term) { term.coefficient != 0 })
  Ok({ terms: sort_terms(terms) })
}

///|
/// Checked integer multiplication; `None` on overflow.
fn checked_int_mul(a : Int, b : Int) -> Int? {
  let product = a.to_int64() * b.to_int64()
  if product > 2147483647L || product < -2147483648L {
    return None
  }
  Some(product.to_int())
}

///|
/// Checked integer addition; `None` on overflow.
fn checked_int_add(a : Int, b : Int) -> Int? {
  let sum = a.to_int64() + b.to_int64()
  if sum > 2147483647L || sum < -2147483648L {
    return None
  }
  Some(sum.to_int())
}

///|
fn poly_mul(
  a : Polynomial,
  b : Polynomial,
  max_terms : Int,
) -> Result[Polynomial, EvalDiagnostic] {
  let terms : Array[Term] = []
  for ta in a.terms {
    for tb in b.terms {
      let coefficient = match checked_int_mul(ta.coefficient, tb.coefficient) {
        None => return Err(EvalDiagnostic::make(IntegerOverflow))
        Some(value) => value
      }
      match
        add_or_merge(terms, {
          coefficient,
          monomial: merge_monomials(ta.monomial, tb.monomial),
        }) {
        Err(e) => return Err(e)
        Ok(_) => ()
      }
      guard terms.length() <= max_terms else {
        return Err(EvalDiagnostic::make(ExpressionTooLarge))
      }
    }
  }
  let terms = terms.filter(fn(term) { term.coefficient != 0 })
  Ok({ terms: sort_terms(terms) })
}

///|
fn poly_pow(
  poly : Polynomial,
  exp : Int,
  options : EvalOptions,
) -> Result[Polynomial, EvalDiagnostic] {
  let mut result : Polynomial = { terms: [unit_term()] }
  let mut i = 0
  while i < exp {
    match poly_mul(result, poly, options.max_terms) {
      Err(e) => return Err(e)
      Ok(product) => result = product
    }
    i = i + 1
  }
  Ok(result)
}

///|
fn add_or_merge(
  terms : Array[Term],
  term : Term,
) -> Result[Unit, EvalDiagnostic] {
  let mut i = 0
  while i < terms.length() {
    if terms[i].monomial == term.monomial {
      let coefficient = match
        checked_int_add(terms[i].coefficient, term.coefficient) {
        None => return Err(EvalDiagnostic::make(IntegerOverflow))
        Some(value) => value
      }
      terms[i] = { coefficient, monomial: terms[i].monomial }
      return Ok(())
    }
    i = i + 1
  }
  terms.push(term)
  Ok(())
}

///|
fn merge_monomials(a : Monomial, b : Monomial) -> Monomial {
  let merged : Array[(MonomialFactor, Int)] = []
  for item in a.factors {
    merged.push(item)
  }
  for item in b.factors {
    let (factor, exp) = item
    let mut i = 0
    let mut found = false
    while i < merged.length() {
      if merged[i].0 == factor {
        merged[i] = (factor, merged[i].1 + exp)
        found = true
        break
      }
      i = i + 1
    }
    if !found {
      merged.push(item)
    }
  }
  { factors: sort_factors(merged) }
}

///|
fn sort_terms(terms : Array[Term]) -> Array[Term] {
  let result = terms
  result.sort_by(term_compare)
  result
}

///|
fn sort_factors(
  factors : Array[(MonomialFactor, Int)],
) -> Array[(MonomialFactor, Int)] {
  let result = factors
  result.sort_by(fn(a, b) {
    compare_strings(a.0.to_canonical_string(), b.0.to_canonical_string())
  })
  result
}

///|
/// Graded lexicographic order: total degree descending, then factor key
/// ascending; constant terms sort after all other degree-zero terms.
fn term_compare(a : Term, b : Term) -> Int {
  let da = a.monomial.degree()
  let db = b.monomial.degree()
  if da != db {
    return if da > db { -1 } else { 1 }
  }
  compare_strings(
    a.monomial.to_canonical_string(),
    b.monomial.to_canonical_string(),
  )
}

///|
fn compare_strings(a : String, b : String) -> Int {
  let la = a.length()
  let lb = b.length()
  let mut i = 0
  while i < la && i < lb {
    let ca = a[i]
    let cb = b[i]
    if ca != cb {
      return if ca < cb { -1 } else { 1 }
    }
    i = i + 1
  }
  if la != lb {
    return if la < lb { -1 } else { 1 }
  }
  0
}
