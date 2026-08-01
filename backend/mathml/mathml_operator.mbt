///|
fn render_operator(
  content : @katex_parser.OperatorContent,
  state : RenderState,
) -> MathMlNode {
  match content {
    SymbolOperator(value) => element("mo", children=[text_node(symbol(value))])
    BodyOperator(body) => element("mo", children=render_expression(body, state))
    NamedOperator(value) =>
      element("mrow", children=[
        element("mi", children=[text_node(strip_command(value))], attributes=[
          ("mathvariant", "normal"),
        ]),
        element("mo", children=[text_node("⁡")]),
      ])
  }
}

///|
fn render_operator_name(
  body : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> MathMlNode {
  let content = render_expression(body, {
      ..state,
      math_variant: Some("normal"),
    })
    .map(node => node.text_content())
    .join("")
  element("mrow", children=[
    element("mi", children=[text_node(content)], attributes=[
      ("mathvariant", "normal"),
    ]),
    element("mo", children=[text_node("⁡")]),
  ])
}
