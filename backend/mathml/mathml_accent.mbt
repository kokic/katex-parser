///|
fn accent_over(
  kind : String,
  body : @katex_parser.ParseNode,
  mark : String,
  attribute : String,
  state : RenderState,
) -> MathMlNode {
  element(
    kind,
    children=[
      render_group(body, state),
      element("mo", children=[text_node(mark)], attributes=[
        ("stretchy", "true"),
      ]),
    ],
    attributes=[(attribute, "true")],
  )
}

///|
fn render_accent(
  label : String,
  is_stretchy : Bool,
  base : @katex_parser.ParseNode,
  state : RenderState,
) -> MathMlNode {
  let mark = if is_stretchy {
    stretchy(label)
  } else {
    element("mo", children=[text_node(symbol(label))])
  }
  element("mover", children=[render_group(base, state), mark], attributes=[
    ("accent", "true"),
  ])
}
