///|
priv enum BinOp {
  Plus
  Minus
  Times
}

///|
priv enum LowerItem {
  ItemNumber(Int)
  ItemOp(BinOp)
  ItemExpr(EvalExpr)
}

///|
/// Lowers a flat list of parse nodes (e.g. the body of an `\eval` group) into
/// an expression tree, applying the implicit multiplication rules for
/// adjacent factors.
pub fn lower_expr(
  nodes : Array[@katex.ParseNode],
  options : EvalOptions,
) -> Result[EvalExpr, EvalDiagnostic] {
  let items = match scan_items(nodes, options) {
    Err(e) => return Err(e)
    Ok(items) => items
  }
  let terms = match split_terms(items) {
    Err(e) => return Err(e)
    Ok(terms) => terms
  }
  let exprs : Array[EvalExpr] = []
  for term in terms {
    let (term_items, neg) = term
    let expr = match parse_factors(term_items) {
      Err(e) => return Err(e)
      Ok(expr) => expr
    }
    let expr = if neg { Mul([Number(-1), expr]) } else { expr }
    exprs.push(expr)
  }
  match exprs.length() {
    0 => Err(EvalDiagnostic::make(InvalidNumber))
    1 => Ok(exprs[0])
    _ => Ok(Add(exprs))
  }
}

///|
/// Lowers a single parse node. Only whitelisted node kinds are recognized;
/// everything else becomes a `Residual` (in partial mode) or an
/// `UnsupportedNode` diagnostic (in strict mode).
pub fn lower_node(
  node : @katex.ParseNode,
  options : EvalOptions,
) -> Result[EvalExpr, EvalDiagnostic] {
  match node {
    OrdGroup(body~, ..) => lower_expr(body, options)
    MathOrd(text~, ..) | TextOrd(text~, ..) =>
      if is_all_digits(text) {
        match parse_decimal_int(text) {
          None => Err(EvalDiagnostic::make(InvalidNumber))
          Some(value) => Ok(Number(value))
        }
      } else if text.length() == 1 || (text.length() > 1 && text[0] == '\\') {
        Ok(Symbol(SymbolKey::make(text)))
      } else {
        unsupported(node, options)
      }
    SupSub(base~, sup~, sub~, ..) =>
      match (base, sub, sup) {
        (Some(base), None, Some(exponent)) =>
          match parse_integer_exponent(exponent) {
            Some(value) =>
              match lower_node(base, options) {
                Err(e) => Err(e)
                Ok(base) => Ok(Pow(base, value))
              }
            None => unsupported_with(node, options, InvalidPower)
          }
        _ => unsupported(node, options)
      }
    GenFrac(numer~, denom~, ..) =>
      match lower_node(numer, options) {
        Err(e) => Err(e)
        Ok(numer) =>
          match lower_node(denom, options) {
            Err(e) => Err(e)
            Ok(denom) => Ok(Div(numer, denom))
          }
      }
    _ => unsupported(node, options)
  }
}

///|
fn scan_items(
  nodes : Array[@katex.ParseNode],
  options : EvalOptions,
) -> Result[Array[LowerItem], EvalDiagnostic] {
  let items : Array[LowerItem] = []
  let mut i = 0
  while i < nodes.length() {
    match nodes[i] {
      MathOrd(text~, ..) | TextOrd(text~, ..) if is_all_digits(text) =>
        match scan_number(nodes, i) {
          Err(e) => return Err(e)
          Ok((value, next)) => {
            items.push(ItemNumber(value))
            i = next
          }
        }
      Atom(family=Mbin, text~, ..) => {
        match text {
          "+" => items.push(ItemOp(Plus))
          "-" => items.push(ItemOp(Minus))
          "*" | "\\cdot" | "\\times" => items.push(ItemOp(Times))
          _ =>
            match push_lowered(items, nodes[i], options) {
              Err(e) => return Err(e)
              Ok(_) => ()
            }
        }
        i = i + 1
      }
      Atom(family=Mopen, text="(", ..) =>
        match scan_paren_end(nodes, i) {
          None =>
            match push_lowered(items, nodes[i], options) {
              Err(e) => return Err(e)
              Ok(_) => ()
            }
          Some(ParenEndNoExp(j)) => {
            let inner : Array[@katex.ParseNode] = []
            for k in (i + 1)..<j {
              inner.push(nodes[k])
            }
            let group = match lower_expr(inner, options) {
              Err(e) => return Err(e)
              Ok(expr) => expr
            }
            items.push(ItemExpr(group))
            i = j + 1
          }
          Some(ParenEndWithExp(j, exponent)) => {
            let inner : Array[@katex.ParseNode] = []
            for k in (i + 1)..<j {
              inner.push(nodes[k])
            }
            let group = match lower_expr(inner, options) {
              Err(e) => return Err(e)
              Ok(expr) => expr
            }
            match parse_integer_exponent(exponent) {
              Some(value) => {
                items.push(ItemExpr(Pow(group, value)))
                i = j + 1
              }
              None =>
                match unsupported_with(nodes[j], options, InvalidPower) {
                  Err(e) => return Err(e)
                  Ok(expr) => {
                    items.push(ItemExpr(expr))
                    i = j + 1
                  }
                }
            }
          }
        }
      _ => {
        match push_lowered(items, nodes[i], options) {
          Err(e) => return Err(e)
          Ok(_) => ()
        }
        i = i + 1
      }
    }
  }
  Ok(items)
}

///|
fn push_lowered(
  items : Array[LowerItem],
  node : @katex.ParseNode,
  options : EvalOptions,
) -> Result[Unit, EvalDiagnostic] {
  match lower_node(node, options) {
    Err(e) => Err(e)
    Ok(expr) => {
      items.push(ItemExpr(expr))
      Ok(())
    }
  }
}

///|
/// Merges a run of digit `MathOrd`/`TextOrd` nodes into an exact integer. A
/// decimal point in the run is rejected (`InvalidNumber`): rational/decimal
/// arithmetic is not supported yet.
fn scan_number(
  nodes : Array[@katex.ParseNode],
  start : Int,
) -> Result[(Int, Int), EvalDiagnostic] {
  let first_text = match nodes[start] {
    MathOrd(text~, ..) | TextOrd(text~, ..) => text
    _ => return Err(EvalDiagnostic::make(InvalidNumber))
  }
  let mut acc = first_text
  let mut j = start + 1
  while j < nodes.length() {
    match nodes[j] {
      MathOrd(text~, ..) | TextOrd(text~, ..) if is_all_digits(text) => {
        acc = acc + text
        j = j + 1
      }
      MathOrd(text~, ..) | TextOrd(text~, ..) if text == "." =>
        return Err(
          EvalDiagnostic::make(InvalidNumber, loc=node_loc(nodes[start])),
        )
      Atom(family=Mpunct, text~, ..) if text == "." =>
        return Err(
          EvalDiagnostic::make(InvalidNumber, loc=node_loc(nodes[start])),
        )
      _ => break
    }
  }
  match parse_decimal_int(acc) {
    None => Err(EvalDiagnostic::make(InvalidNumber, loc=node_loc(nodes[start])))
    Some(value) => Ok((value, j))
  }
}

///|
/// Parses digit text into an `Int`, rejecting overflow.
fn parse_decimal_int(text : String) -> Int? {
  let mut value = 0
  for c in text {
    let digit = c.to_int() - '0'.to_int()
    if value > (2147483647 - digit) / 10 {
      return None
    }
    value = value * 10 + digit
  }
  Some(value)
}

///|
/// Splits the item stream into terms at binary `+`/`-`; unary signs stay in
/// the term and are handled at factor level. Returns `(term items, negated)`.
fn split_terms(
  items : Array[LowerItem],
) -> Result[Array[(Array[LowerItem], Bool)], EvalDiagnostic] {
  let terms : Array[(Array[LowerItem], Bool)] = []
  let mut cur : Array[LowerItem] = []
  let mut neg = false
  let mut i = 0
  while i < items.length() {
    match items[i] {
      ItemOp(Plus) => {
        terms.push((cur, neg))
        cur = []
        neg = false
        i = i + 1
      }
      ItemOp(Minus) => {
        let binary = i > 0 && is_value_item(items[i - 1])
        if binary {
          terms.push((cur, neg))
          cur = []
          neg = true
        } else {
          cur.push(items[i])
        }
        i = i + 1
      }
      item => {
        cur.push(item)
        i = i + 1
      }
    }
  }
  terms.push((cur, neg))
  Ok(terms)
}

///|
fn is_value_item(item : LowerItem) -> Bool {
  match item {
    ItemNumber(_) | ItemExpr(_) => true
    ItemOp(_) => false
  }
}

///|
/// Builds a factor list from a term's items: `*` separates factors, adjacent
/// value items multiply implicitly, and unary `-` negates the next factor.
fn parse_factors(items : Array[LowerItem]) -> Result[EvalExpr, EvalDiagnostic] {
  let factors : Array[EvalExpr] = []
  let mut i = 0
  while i < items.length() {
    match items[i] {
      ItemOp(Times) | ItemOp(Plus) => i = i + 1
      ItemOp(Minus) => {
        guard i + 1 < items.length() else {
          return Err(EvalDiagnostic::make(InvalidNumber))
        }
        i = i + 1
        match items[i] {
          ItemNumber(value) => {
            factors.push(Number(value.neg()))
            i = i + 1
          }
          ItemExpr(expr) => {
            factors.push(Mul([Number(-1), expr]))
            i = i + 1
          }
          _ => return Err(EvalDiagnostic::make(InvalidNumber))
        }
      }
      ItemNumber(value) => {
        factors.push(Number(value))
        i = i + 1
      }
      ItemExpr(expr) => {
        factors.push(expr)
        i = i + 1
      }
    }
  }
  match factors.length() {
    0 => Err(EvalDiagnostic::make(InvalidNumber))
    1 => Ok(factors[0])
    _ => Ok(Mul(factors))
  }
}

///|
priv enum ParenEnd {
  /// The group is closed by a standalone `)` atom at the given index.
  ParenEndNoExp(Int)
  /// The group is closed by a superscripted `)` atom (`(x+1)^2` parses as
  /// `SupSub(base=Atom(")"), sup=...)`); the node carries the exponent.
  ParenEndWithExp(Int, @katex.ParseNode)
}

///|
/// Returns the node that closes the paren group opened at `start`, counting
/// nested parens; `None` when unbalanced.
fn scan_paren_end(nodes : Array[@katex.ParseNode], start : Int) -> ParenEnd? {
  let mut depth = 0
  let mut j = start
  while j < nodes.length() {
    match nodes[j] {
      Atom(family=Mopen, text="(", ..) => depth = depth + 1
      Atom(family=Mclose, text=")", ..) => {
        depth = depth - 1
        if depth == 0 {
          return Some(ParenEndNoExp(j))
        }
      }
      SupSub(
        base=Some(Atom(family=Mclose, text=")", ..)),
        sup=Some(exponent),
        sub=None,
        ..
      ) if depth == 1 => return Some(ParenEndWithExp(j, exponent))
      _ => ()
    }
    j = j + 1
  }
  None
}

///|
/// Accepts a plain integer exponent: digit `MathOrd`/`TextOrd`, optionally
/// wrapped in an `OrdGroup` and optionally preceded by a unary minus.
fn parse_integer_exponent(node : @katex.ParseNode) -> Int? {
  let (digits, neg) = match node {
    MathOrd(text~, ..) | TextOrd(text~, ..) if is_all_digits(text) =>
      (text, false)
    OrdGroup(body~, ..) => {
      let mut neg = false
      let mut digits = ""
      let mut i = 0
      if body.length() > 0 && body[0] is Atom(family=Mbin, text="-", ..) {
        neg = true
        i = 1
      }
      while i < body.length() {
        match body[i] {
          MathOrd(text~, ..) | TextOrd(text~, ..) if is_all_digits(text) => {
            digits = digits + text
            i = i + 1
          }
          _ => return None
        }
      }
      guard digits.length() > 0 else { return None }
      (digits, neg)
    }
    _ => return None
  }
  match parse_decimal_int(digits) {
    None => None
    Some(value) => Some(if neg { -value } else { value })
  }
}

///|
fn unsupported(
  node : @katex.ParseNode,
  options : EvalOptions,
) -> Result[EvalExpr, EvalDiagnostic] {
  unsupported_with(node, options, UnsupportedNode)
}

///|
fn unsupported_with(
  node : @katex.ParseNode,
  options : EvalOptions,
  kind : EvalFailureKind,
) -> Result[EvalExpr, EvalDiagnostic] {
  match options.mode {
    Strict => Err(EvalDiagnostic::make(kind, loc=node_loc(node)))
    Partial => Ok(Residual(node))
  }
}

///|
fn is_all_digits(text : String) -> Bool {
  if text.length() == 0 {
    return false
  }
  for c in text {
    if c < '0' || c > '9' {
      return false
    }
  }
  true
}

///|
fn node_loc(node : @katex.ParseNode) -> @katex.SourceLocation? {
  match node {
    OrdGroup(loc~, ..) => loc
    MathOrd(loc~, ..) => loc
    TextOrd(loc~, ..) => loc
    Atom(loc~, ..) => loc
    _ => None
  }
}
