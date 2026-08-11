///|
fn render_text(
  body : Array[@katex_parser.ParseNode],
  font : String,
  state : RenderState,
) -> String {
  let base = match plain_text_of(body) {
    Some(text) => quote_string(text)
    None =>
      "(\{body.map(node => render_text_child(node, state)).join(" ")})"
  }
  match font {
    "\\textbf" => "#strong[$text\{base}$]"
    "\\textit" | "\\emph" => "#emph[$text\{base}$]"
    _ => "text\{base}"
  }
}

///|
fn render_text_child(
  node : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  match node {
    TextOrd(text~, ..)
    | MathOrd(text~, ..)
    | Spacing(text~, ..) =>
      quote_string(@katex_parser.unicode_symbol(text).unwrap_or(text))
    _ => render_node(node, state)
  }
}

///|
let font_functions : Map[String, String] = Map::from_array([
  ("mathrm", "upright"),
  ("mathit", "italic"),
  ("mathbf", "bold"),
  ("mathbb", "bb"),
  ("mathcal", "cal"),
  ("mathfrak", "frak"),
  ("mathscr", "scr"),
  ("mathsf", "sans"),
  ("mathtt", "mono"),
])

///|
fn render_font(
  font : String,
  body : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  match font_functions.get(font) {
    Some(name) =>
      "\{name}(\{wrap_arg(render_node(body, state))})"
    None if font == "mathsfit" =>
      "italic(sans(\{wrap_arg(render_node(body, state))}))"
    // mathnormal, bold (for \pmb bodies handled elsewhere): pass through
    _ => render_node(body, state)
  }
}
