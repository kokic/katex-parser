///|
fn render_sized_delim(
  delim : String,
  mclass : @katex_parser.AtomFamily,
  size : Int,
) -> MathMlNode {
  let fence = match mclass {
    Mopen | Mclose => "true"
    _ => "false"
  }
  let height = match size {
    1 => "1.2em"
    2 => "1.8em"
    3 => "2.4em"
    _ => "3em"
  }
  let children = if delim == "." { [] } else { [text_node(symbol(delim))] }
  element("mo", children~, attributes=[
    ("fence", fence),
    ("stretchy", "true"),
    ("minsize", height),
    ("maxsize", height),
  ])
}

///|
fn render_fence(delim : String, color : String?) -> MathMlNode {
  let attrs = [
    ("fence", "true"),
    ..color.map_or([], value => [("mathcolor", value)]),
  ]
  element("mo", children=[text_node(symbol(delim))], attributes=attrs)
}

///|
fn render_middle(delim : String) -> MathMlNode {
  let value = if delim == "\\vert" || delim == "|" {
    "|"
  } else {
    symbol(delim)
  }
  element("mo", children=[text_node(value)], attributes=[
    ("fence", "true"),
    ("lspace", "0.05em"),
    ("rspace", "0.05em"),
  ])
}

///|
fn render_left_right(
  body : Array[@katex_parser.ParseNode],
  left : String,
  right : String,
  right_color : String?,
  state : RenderState,
) -> MathMlNode {
  let children = (if left == "." { [] } else { [render_fence(left, None)] }) +
    render_expression(body, state) +
    (if right == "." { [] } else { [render_fence(right, right_color)] })
  make_row(children)
}
