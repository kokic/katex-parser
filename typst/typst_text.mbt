///|
fn render_text(
  body : Array[@katex.ParseNode],
  font : String,
  in_markup~ : Bool = false,
) -> String {
  let plain = plain_text_of(body)
  let arg = plain.map_or_else(() => "[\{text_markup(body)}]", quote_string)
  match font {
    "\\textbf" => "#strong(\{arg})"
    "\\textit" | "\\emph" => "#emph(\{arg})"
    _ if !in_markup && plain is Some(_) => arg
    _ => "#\{arg}"
  }
}

///|
/// In a mixed text argument only embedded math belongs in `$...$`.
/// Emit literal runs as strings so punctuation cannot become Typst markup.
fn text_markup(body : Array[@katex.ParseNode]) -> String {
  let markup = StringBuilder()
  let run = StringBuilder()
  fn flush() {
    if !run.is_empty() {
      markup.write_string("#\{quote_string(run.to_string())}")
      run.reset()
    }
  }
  for node in body {
    if text_atom(node) is Some(text) {
      run.write_string(text)
      continue
    }
    flush()
    match node {
      OrdGroup(body=group, ..) => markup.write_string(text_markup(group))
      Text(body=group, font~, ..) =>
        markup.write_string(render_text(group, font, in_markup=true))
      _ => {
        let math = render_node(node, RenderState::at(TextStyle))
        if math != "" {
          markup.write_string("$\{math}$")
        }
      }
    }
  }
  flush()
  markup.to_string()
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
  body : @katex.ParseNode,
  state : RenderState,
) -> String {
  // The mod macros use an upright `\rm mod`; other font changes must not
  // turn math letters into a named operator merely because of their spelling.
  if font == "mathrm" &&
    body is OrdGroup(body=nodes, ..) &&
    plain_text_of(nodes) == Some("mod") {
    return "mod"
  }
  guard font_functions.get(font) is Some(name) else {
    guard font != "mathsfit" else {
      return "italic(\{math_fn("sans", render_node(body, state))})"
    }
    // mathnormal, bold (for \pmb bodies handled elsewhere): pass through
    return render_node(body, state)
  }
  math_fn(name, render_node(body, state))
}
