///|
/// Resolves a TeX symbol name (or a raw Unicode string) to its Unicode
/// rendering via the parser's public registry, then applies math escaping.
/// Mirrors the Unicode backend's `render_symbol`.
fn render_symbol(text : String) -> String {
  escape_math(@katex_parser.unicode_symbol(text).unwrap_or(text))
}

///|
fn render_op(
  content : @katex_parser.OperatorContent,
  state : RenderState,
) -> String {
  match content {
    SymbolOperator(text) => render_symbol(text)
    NamedOperator(text) => render_named_operator(text)
    BodyOperator(body) => "op(\{wrap_arg(render_nodes(body, state))})"
  }
}

///|
/// Typst predefines these operator names; emitting the bare name gives proper
/// limit placement in display mode. Others fall back to `op("...")`.
let typst_operator_names : Map[String, Bool] = Map::from_array([
  ("arccos", true),
  ("arcsin", true),
  ("arctan", true),
  ("arg", true),
  ("cos", true),
  ("cosh", true),
  ("cot", true),
  ("coth", true),
  ("csc", true),
  ("csch", true),
  ("ctg", true),
  ("deg", true),
  ("det", true),
  ("dim", true),
  ("exp", true),
  ("gcd", true),
  ("hom", true),
  ("id", true),
  ("im", true),
  ("inf", true),
  ("ker", true),
  ("lg", true),
  ("lim", true),
  ("liminf", true),
  ("limsup", true),
  ("ln", true),
  ("log", true),
  ("max", true),
  ("min", true),
  ("mod", true),
  ("Pr", true),
  ("sec", true),
  ("sech", true),
  ("sin", true),
  ("sinc", true),
  ("sinh", true),
  ("sup", true),
  ("tan", true),
  ("tanh", true),
  ("tg", true),
  ("tr", true),
  ("lcm", true),
  ("Pr", true),
])

///|
fn render_named_operator(text : String) -> String {
  let name = text.strip_prefix("\\").map(StringView::to_owned).unwrap_or(text)
  if typst_operator_names.contains(name) {
    name
  } else {
    "op(\"\{escape_string(name)}\")"
  }
}

///|
fn render_operatorname(
  body : Array[@katex_parser.ParseNode],
  limits : Bool,
  state : RenderState,
) -> String {
  let text = plain_text_of(body)
  let content = text.map_or(wrap_arg(render_nodes(body, state)), quote_string)
  let limits_arg = if limits { ", limits: #true" } else { "" }
  "op(\{content}\{limits_arg})"
}

///|
/// Collects the plain text of a list of purely textual nodes (text ordinals
/// and spaces), or `None` if it contains any math structure. Parts are joined
/// without separators; the result is always embedded in a quoted string, so
/// spaces are preserved verbatim.
fn plain_text_of(nodes : Array[@katex_parser.ParseNode]) -> String? {
  let parts : Array[String] = nodes.filter_map(node => {
    match node {
      TextOrd(text~, ..) | MathOrd(text~, ..) | Spacing(text~, ..) =>
        Some(@katex_parser.unicode_symbol(text).unwrap_or(text))
      _ => None
    }
  })
  if parts.length() == nodes.length() {
    Some(parts.join(""))
  } else {
    None
  }
}
