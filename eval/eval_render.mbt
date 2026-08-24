///|
/// Renders a computed expression back into a `@katex_parser.ParseNode`, inserting grouping
/// and parentheses according to operator precedence
/// (`Add < Mul < Div < Pow < Atom`).
pub fn render(
  expr : EvalExpr,
) -> Result[@katex_parser.ParseNode, EvalDiagnostic] {
  Ok(render_expr(expr, 0))
}

///|
fn precedence(expr : EvalExpr) -> Int {
  match expr {
    Add(_) => 1
    Mul(_) => 2
    Div(_, _) => 3
    Pow(_, _) => 4
    _ => 5
  }
}

///|
fn render_expr(expr : EvalExpr, parent_prec : Int) -> @katex_parser.ParseNode {
  let prec = precedence(expr)
  let node = match expr {
    Number(value) => render_number(value)
    Symbol(symbol) =>
      @katex_parser.ParseNode::MathOrd(
        mode=@katex_parser.Mode::Math,
        loc=None,
        text=symbol.text,
      )
    Add(children) => render_add(children)
    Mul(children) => render_mul(children)
    Pow(base, exp) => render_pow(base, exp)
    Div(numer, denom) =>
      @katex_parser.ParseNode::GenFrac(
        mode=@katex_parser.Mode::Math,
        numer=render_expr(numer, 3),
        denom=render_expr(denom, 3),
        continued=false,
        has_bar_line=true,
        bar_size=None,
        left_delim=None,
        right_delim=None,
      )
    Residual(node) => node
  }
  if prec < parent_prec {
    @katex_parser.ParseNode::OrdGroup(
      mode=@katex_parser.Mode::Math,
      loc=None,
      body=[node],
      semisimple=false,
    )
  } else {
    node
  }
}

///|
fn render_add(children : Array[EvalExpr]) -> @katex_parser.ParseNode {
  let body : Array[@katex_parser.ParseNode] = []
  let mut first = true
  for child in children {
    let (sign, magnitude) = split_sign(child)
    if first {
      if sign < 0 {
        body.push(minus_atom())
        body.push(render_expr(magnitude, 2))
      } else {
        body.push(render_expr(magnitude, 2))
      }
      first = false
    } else {
      body.push(
        if sign < 0 {
          minus_atom()
        } else {
          @katex_parser.ParseNode::Atom(
            mode=@katex_parser.Mode::Math,
            loc=None,
            family=@katex_parser.AtomFamily::Mbin,
            text="+",
          )
        },
      )
      body.push(render_expr(magnitude, 2))
    }
  }
  @katex_parser.ParseNode::OrdGroup(
    mode=@katex_parser.Mode::Math,
    loc=None,
    body~,
    semisimple=false,
  )
}

///|
/// Extracts the sign of an addition term, leaving a non-negative magnitude.
fn split_sign(expr : EvalExpr) -> (Int, EvalExpr) {
  match expr {
    Number(value) if value < 0 => (-1, Number(-value))
    Mul(children) if children.length() > 0 =>
      match children[0] {
        Number(coefficient) if coefficient < 0 => {
          let rest : Array[EvalExpr] = [Number(-coefficient)]
          for i in 1..<children.length() {
            rest.push(children[i])
          }
          (-1, Mul(rest))
        }
        _ => (1, expr)
      }
    _ => (1, expr)
  }
}

///|
fn render_mul(children : Array[EvalExpr]) -> @katex_parser.ParseNode {
  let body : Array[@katex_parser.ParseNode] = []
  let mut first = true
  for child in children {
    match child {
      Number(coefficient) if coefficient < 0 && first => {
        body.push(minus_atom())
        body.push(render_expr(Number(-coefficient), 3))
      }
      _ => body.push(render_expr(child, 3))
    }
    first = false
  }
  @katex_parser.ParseNode::OrdGroup(
    mode=@katex_parser.Mode::Math,
    loc=None,
    body~,
    semisimple=false,
  )
}

///|
fn render_pow(base : EvalExpr, exp : Int) -> @katex_parser.ParseNode {
  let base_node = render_expr(base, 4)
  let base_node = match base {
    Number(value) if value < 0 =>
      @katex_parser.ParseNode::OrdGroup(
        mode=@katex_parser.Mode::Math,
        loc=None,
        body=[base_node],
        semisimple=false,
      )
    _ => base_node
  }
  @katex_parser.ParseNode::SupSub(
    mode=@katex_parser.Mode::Math,
    base=Some(base_node),
    sup=Some(render_exponent(exp)),
    sub=None,
  )
}

///|
fn render_exponent(exp : Int) -> @katex_parser.ParseNode {
  if exp >= 0 {
    @katex_parser.ParseNode::MathOrd(
      mode=@katex_parser.Mode::Math,
      loc=None,
      text=exp.to_string(),
    )
  } else {
    @katex_parser.ParseNode::OrdGroup(
      mode=@katex_parser.Mode::Math,
      loc=None,
      body=[
        minus_atom(),
        @katex_parser.ParseNode::MathOrd(
          mode=@katex_parser.Mode::Math,
          loc=None,
          text=(-exp).to_string(),
        ),
      ],
      semisimple=false,
    )
  }
}

///|
fn render_number(value : Int) -> @katex_parser.ParseNode {
  if value < 0 {
    return @katex_parser.ParseNode::OrdGroup(
      mode=@katex_parser.Mode::Math,
      loc=None,
      body=[minus_atom(), render_number(-value)],
      semisimple=false,
    )
  }
  @katex_parser.ParseNode::MathOrd(
    mode=@katex_parser.Mode::Math,
    loc=None,
    text=value.to_string(),
  )
}

///|
fn minus_atom() -> @katex_parser.ParseNode {
  @katex_parser.ParseNode::Atom(
    mode=@katex_parser.Mode::Math,
    loc=None,
    family=@katex_parser.AtomFamily::Mbin,
    text="-",
  )
}
