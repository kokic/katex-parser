///|
fn render_left_right(
  body : Array[@katex.ParseNode],
  left : String,
  right : String,
  state : RenderState,
) -> String {
  match body {
    [array] if array is @katex.ParseNode::Array(..) =>
      render_leftright_array(array, left, right, state)
    _ => wrap_lr(render_nodes(body, state), left, right)
  }
}

///|
/// Both delimiters belong to the same `lr` as the body, even when one side
/// is invisible: its height comes from the body, not a fixed size.
fn wrap_lr(content : String, left : String, right : String) -> String {
  let l = render_lr_delim(left)
  let r = render_lr_delim(right)
  guard l != "" || r != "" else { return content }
  "lr(\{[l, wrap_arg(content), r].filter(s => s != "").join(" ")})"
}

///|
fn render_delim_sizing(size : Int32, delim : String) -> String {
  // KaTeX `\big`..`\Bigg` carry sizes 1..4, indexing the em table 0-based.
  let sizes = [1.2, 1.8, 2.4, 3.0]
  let em = sizes.get(size - 1).unwrap_or(1.2)
  "lr(size: #\{em}em, \{render_lr_delim(delim)})"
}

///|
/// Renders a delimiter outside of an `lr` wrapper (e.g. `\right` alone).
fn render_delimiter(delim : String) -> String {
  guard !@backend.is_null_delimiter(delim) else { "" }
  render_symbol(delim)
}

///|
/// Renders a delimiter as `lr(...)` content: `(` `)` `[` `]` and `{` `}` are
/// escaped with a backslash since a bare one would open a brace group.
fn render_lr_delim(delim : String) -> String {
  guard !@backend.is_null_delimiter(delim) else { "" }
  match delim {
    "(" => "\\("
    ")" => "\\)"
    "[" => "\\["
    "]" => "\\]"
    "{" | "\\{" => "\\{"
    "}" | "\\}" => "\\}"
    _ => escape_math(delim_symbol(delim))
  }
}

///|
fn delim_symbol(delim : String) -> String {
  match delim {
    "|" | "\\vert" | "\\lvert" | "\\rvert" => "|"
    _ => @backend.resolve_symbol(delim)
  }
}
