///|
fn render_left_right(
  body : Array[@katex_parser.ParseNode],
  left : String,
  right : String,
  state : RenderState,
) -> String {
  match body {
    [array] if array is @katex_parser.ParseNode::Array(..) =>
      render_leftright_array(array, left, right, state)
    _ => {
      let l = render_lr_delim(left)
      let r = render_lr_delim(right)
      if l == "" && r == "" {
        render_nodes(body, state)
      } else if l == "" || r == "" {
        let visible = if l == "" { r } else { l }
        "\{render_nodes(body, state)} lr(size: #2em, \{visible})"
      } else {
        "lr(\{l} \{render_nodes(body, state)} \{r})"
      }
    }
  }
}

///|
fn render_delim_sizing(size : Int, delim : String) -> String {
  // KaTeX `\big`..`\Bigg` carry sizes 1..4, indexing the em table 0-based.
  let sizes = [1.2, 1.8, 2.4, 3.0]
  let index = size - 1
  let em = if index >= 0 && index < sizes.length() { sizes[index] } else { 1.2 }
  "lr(size: #\{em}em, \{render_lr_delim(delim)})"
}

///|
/// Renders a delimiter outside of an `lr` wrapper (e.g. `\right` alone).
fn render_delimiter(delim : String) -> String {
  if delim == "." {
    ""
  } else {
    render_symbol(delim)
  }
}

///|
/// Renders a delimiter as `lr(...)` content: `(` `)` `[` `]` are always
/// escaped; `{` `}` are escaped via code points since a bare `{` would open a
/// brace group.
fn render_lr_delim(delim : String) -> String {
  if delim == "." {
    ""
  } else {
    match delim {
      "(" => "\\("
      ")" => "\\)"
      "[" => "\\["
      "]" => "\\]"
      "{" | "\\{" => "\\u{7b}"
      "}" | "\\}" => "\\u{7d}"
      _ => render_symbol(delim)
    }
  }
}
