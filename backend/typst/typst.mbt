///|
/// Renders parsed KaTeX nodes as Typst math source.
///
/// The output is a fragment of Typst math-mode syntax (the content that would
/// appear between `$...$`), suitable for embedding in a Typst document.
/// Approximations are allowed and documented in the emission sites; no layout
/// or measurement is performed here.
pub fn render(nodes : Array[@katex_parser.ParseNode]) -> String {
  render_nodes(nodes, { style: @katex_parser.StyleLevel::TextStyle })
}

///|
priv struct RenderState {
  style : @katex_parser.StyleLevel
}

///|
fn render_nodes(
  nodes : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> String {
  let rendered = nodes.map(node => render_node(node, state))
  join_math(fold_norm(fold_primes(merge_not(rendered))))
}

///|
/// Consecutive prime marks (`x' ' '` from a `\prime` OrdGroup) fold into a
/// single run: Typst reads `z'''` directly, and the folded run no longer
/// trips the script-parenthesizing rule (which only wraps on spaces).
fn fold_primes(items : Array[String]) -> Array[String] {
  let mut i = 0
  while i < items.length() {
    if items[i] == "′" {
      let mut count = 0
      while i < items.length() && items[i] == "′" {
        count = count + 1
        items[i] = ""
        i = i + 1
      }
      items[i - count] = "′".repeat(count)
    } else {
      i = i + 1
    }
  }
  items
}

///|
/// Joins rendered items, dropping the space around `(` `)` `[` `]` boundaries
/// (`f ( x )` reads better as `f(x)`, and Typst absorbs such spaces anyway).
/// Spaces between letters stay (`a b`), since `ab` would parse as a single
/// multi-letter variable; code-mode calls (`#h(...)`) keep their spaces.
/// Empty items (cleared by `fold_primes`/`merge_not`) are skipped.
fn join_math(items : Array[String]) -> String {
  let sb = StringBuilder()
  let mut prev = ""
  for i in 0..<items.length() {
    let text = items[i]
    if text == "" {
      continue
    }
    if prev != "" && !no_space_between(prev, text) {
      sb.write_string(" ")
    }
    sb.write_string(text)
    prev = text
  }
  sb.to_string()
}

///|
fn no_space_between(left : String, right : String) -> Bool {
  !left.has_prefix("#") &&
  !right.has_prefix("#") &&
  (is_open_paren(left) || is_open_paren(right) || is_close_paren(right))
}

///|
/// Spaces are dropped around bare bracket items in `(` content `)` positions:
/// `f` + `(` + `x` + `)` -> `f(x)`. A close bracket followed by an operator
/// (`)` + `+`) keeps the space, and a complete expression such as `norm(b)`
/// is not a bracket item at all (`a norm(b) c`).
fn is_open_paren(text : String) -> Bool {
  text == "(" || text == "["
}

///|
fn is_close_paren(text : String) -> Bool {
  text == ")" || text == "]"
}

///|
/// `\Vert x \Vert` (and the `\lVert`/`\rVert` spellings) render as a bare `‖`
/// on each side; folds the pair into Typst's `norm(...)`.
fn fold_norm(items : Array[String]) -> Array[String] {
  for i in 0..<(items.length() - 1) {
    if items[i] == "‖" {
      for j in (i + 1)..<items.length() {
        if items[j] == "‖" && j > i + 1 {
          let body = items.view(start=i + 1, end=j).join(" ")
          items[i] = "norm(\{body})"
          for k in (i + 1)..<=j {
            items[k] = ""
          }
          break
        }
      }
    }
  }
  items
}

///|
/// The `\not` macro contributes a bare combining long solidus (U+0338) through
/// its MathML branch. Mirroring the Unicode backend, the mark is folded into
/// the following single symbol as `cancel(...)` so the slash overlays it.
fn merge_not(items : Array[String]) -> Array[String] {
  for i in 0..<(items.length() - 1) {
    let next = items[i + 1]
    if items[i] == "\u{0338}" && is_single_symbol(next) {
      items[i] = "cancel(\{next})"
      items[i + 1] = ""
    }
  }
  items
}

///|
fn is_single_symbol(text : String) -> Bool {
  text.length() == 1 && !text.contains("\\")
}

///|
fn render_node(node : @katex_parser.ParseNode, state : RenderState) -> String {
  match node {
    Internal(..) | EnvironmentEnd(..) => ""
    Raw(string~, ..) => render_symbol(string)
    ColorToken(color~, ..) => render_symbol(color)
    TextOrd(text~, ..)
    | MathOrd(text~, ..)
    | AccentToken(text~, ..)
    | OperatorToken(text~, ..)
    | Atom(text~, ..) => render_symbol(text)
    Spacing(text~, ..) => render_spacing(text)
    Size(value~, ..) => render_measurement(value)
    Url(url~, ..) => url
    Styling(body~, style~, ..) => render_styling(body, style)
    Sqrt(body~, index=None, ..) => "sqrt(\{wrap_arg(render_node(body, state))})"
    Sqrt(body~, index=Some(index), ..) =>
      "root(\{wrap_arg(render_node(index, state))}, \{wrap_arg(render_node(body, state))})"
    Infix(..) => unsupported_comment("\\over/\\atop infix")
    GenFrac(numer~, denom~, has_bar_line~, left_delim~, right_delim~, ..) =>
      render_genfrac(numer, denom, has_bar_line, left_delim, right_delim, state)
    Text(body~, font~, ..) => render_text(body, font, state)
    Font(font~, body~, ..) => render_font(font, body, state)
    MClass(body~, ..) => render_nodes(body, state)
    Op(content~, ..) => render_op(content, state)
    OperatorName(body~, limits~, ..) => render_operatorname(body, limits, state)
    Overline(body~, ..) => "overline(\{wrap_arg(render_node(body, state))})"
    Underline(body~, ..) => "underline(\{wrap_arg(render_node(body, state))})"
    Smash(body~, ..) => render_node(body, state)
    Phantom(..) | VPhantom(..) => "#box(height: 0.5em)"
    Pmb(body~, ..) => render_nodes(body, state)
    VCenter(body~, ..) => render_node(body, state)
    Rule(width~, height~, ..) =>
      "#rect(width: \{render_measurement(width)}, height: \{render_measurement(height)})"
    RaiseBox(dy~, body~, ..) =>
      "#place(dy: \{render_measurement(dy)}, $\{render_node(body, state)}$)"
    HBox(body~, ..) => render_nodes(body, state)
    Lap(..) => unsupported_comment("\\llap/\\rlap/\\clap")
    MathChoice(display~, text~, script~, scriptscript~, ..) =>
      render_nodes(
        math_choice_variant(display, text, script, scriptscript, state.style),
        state,
      )
    Sizing(size~, body~, ..) => render_sizing(size, body, state)
    HorizBrace(label~, base~, ..) => render_horiz_brace(label, base, state)
    XArrow(label~, body~, below~, ..) =>
      render_xarrow(label, body, below, state)
    AccentUnder(..) => unsupported_comment("under-accents")
    DelimSizing(size~, delim~, ..) => render_delim_sizing(size, delim)
    LeftRightRight(delim~, ..) => render_delimiter(delim)
    LeftRight(body~, left~, right~, ..) =>
      render_left_right(body, left, right, state)
    Middle(delim~, ..) => "mid(\{wrap_arg(render_delimiter(delim))})"
    Kern(dimension~, ..) => render_kern(dimension)
    Enclose(label~, body~, background_color~, border_color~, ..) =>
      render_enclose(label, body, background_color, border_color, state)
    Href(href~, body~, ..) =>
      "#link(\"\{escape_string(href)}\")[$\{render_nodes(body, state)}$]"
    Html(..) => unsupported_comment("\\htmlClass/\\htmlId")
    IncludeGraphics(width~, height~, src~, ..) =>
      "#image(\"\{escape_string(src)}\", width: \{render_measurement(width)}, height: \{render_measurement(height)})"
    Tag(..) => unsupported_comment("\\tag")
    Array(..) => render_array(node, state)
    CdLabel(..) | CdParent(..) | Cr(..) => unsupported_comment("cd environment")
    HtmlMathML(mathml~, ..) => render_nodes(mathml, state)
    OrdGroup(body~, ..) => render_nodes(body, state)
    SupSub(base~, sup~, sub~, ..) => render_sup_sub(base, sup, sub, state)
    Accent(label~, base~, ..) => render_accent(label, base, state)
    Verb(body~, ..) => "#raw(\"\{escape_string(body)}\")"
    Color(color~, body~, ..) => render_color(color, body, state)
  }
}

///|
fn math_choice_variant(
  display : Array[@katex_parser.ParseNode],
  text : Array[@katex_parser.ParseNode],
  script : Array[@katex_parser.ParseNode],
  scriptscript : Array[@katex_parser.ParseNode],
  style : @katex_parser.StyleLevel,
) -> Array[@katex_parser.ParseNode] {
  match style {
    DisplayStyle => display
    TextStyle => text
    ScriptStyle => script
    ScriptScriptStyle => scriptscript
  }
}

///|
/// Escapes characters that have special meaning in Typst math mode. Always
/// applied to symbol text; a bare `/` would otherwise parse as a fraction and
/// a bare `$` would terminate the surrounding equation.
fn escape_math(text : String) -> String {
  text
  .replace(old="\\", new="\\u{5c}")
  .replace(old="/", new="\\/")
  .replace(old="#", new="\\#")
  .replace(old="&", new="\\&")
  .replace(old="%", new="\\%")
  .replace(old="$", new="\\$")
}

///|
/// Escapes a double-quoted Typst string literal.
fn escape_string(text : String) -> String {
  text.replace(old="\\", new="\\\\").replace(old="\"", new="\\\"")
}

///|
fn quote_string(text : String) -> String {
  "\"\{escape_string(text)}\""
}

///|
/// Renders a length for use inside `#...(...)` calls (code mode), where the
/// `ex` unit is not lexable (`0.1ex` reads as the float `0.1e`). `ex` is
/// converted to `em` with the standard x-height ratio of 0.5.
fn render_measurement(measurement : @katex_parser.Measurement) -> String {
  if measurement.unit == "ex" {
    let em = (measurement.number * 0.5 * 1000.0).round() / 1000.0
    "\{em}em"
  } else {
    "\{measurement.number}\{measurement.unit}"
  }
}

///|
/// Wraps a rendered argument in grouping parentheses when it contains a
/// top-level `,` `;` or `:` that would otherwise be parsed as an argument or
/// named-argument separator. The parentheses render visibly; such cases are
/// rare and documented as an approximation.
fn wrap_arg(content : String) -> String {
  if contains_top_level_separator(content) {
    "(\{content})"
  } else {
    content
  }
}

///|
fn contains_top_level_separator(text : String) -> Bool {
  let mut depth = 0
  let mut in_string = false
  for c in text {
    if c == '"' {
      in_string = !in_string
    } else if !in_string {
      if c == '(' || c == '[' || c == '{' {
        depth = depth + 1
      } else if c == ')' || c == ']' || c == '}' {
        depth = depth - 1
      } else if depth == 0 {
        if c == ',' || c == ';' || c == ':' {
          return true
        }
      }
    }
  }
  false
}

///|
fn unsupported_comment(reason : String) -> String {
  "/* unsupported: \{reason} */"
}
