///|
/// Renders parsed KaTeX nodes as Typst math source.
///
/// The output is a fragment of Typst math-mode syntax (the content that would
/// appear between `$...$`). Embed it in a block equation (`$ … $`) when
/// the nodes were parsed with `display_mode=true`, otherwise in an inline one.
/// Approximations are allowed and documented in the emission sites; no layout
/// or measurement is performed here.
pub fn render(nodes : Array[@katex.ParseNode]) -> String {
  match nodes {
    // The parser marks the equation's own style with a font reset, unlike
    // an explicit `\displaystyle` or `\dfrac` in an inline equation.
    [Styling(mode=Math, style=DisplayStyle, reset_font=true, body~)] =>
      render_nodes(body, RenderState::at(DisplayStyle))
    _ => render_nodes(nodes, RenderState::at(TextStyle))
  }
}

///|
priv struct RenderState {
  tex : @katex.StyleLevel
  typst : @katex.StyleLevel
  in_arg : Bool
}

///|
fn RenderState::at(style : @katex.StyleLevel) -> RenderState {
  { tex: style, typst: style, in_arg: false, }
}

///|
fn render_nodes(nodes : Array[@katex.ParseNode], state : RenderState) -> String {
  let pairs = norm_pairs(nodes)
  fn render_range(start : Int32, end : Int32) -> String {
    let items = []
    for i = start; i < end; {
      if pairs.get(i) is Some(close) {
        let body = render_range(i + 1, close)
        let norm = math_fn("norm", if body == "" { "#[]" } else { body })
        items.push(
          match nodes[close] {
            SupSub(sup~, sub~, ..) => with_scripts(norm, sup, sub, state)
            _ => norm
          },
        )
        continue close + 1
      }
      items.push(render_node(nodes[i], state))
      continue i + 1
    }
    join_math(fold_primes(merge_not(items)))
  }
  render_range(0, nodes.length())
}

///|
/// Keep literal prime glyphs together. Postfix primes on a base are handled
/// by `script_marks` while the superscript nodes are still available.
fn fold_primes(items : Array[String]) -> Array[String] {
  let mut i = 0
  while i < items.length() {
    guard items[i] == "′" else {
      i = i + 1
      continue
    }
    let mut j = i
    while j < items.length() && items[j] == "′" {
      j = j + 1
    }
    let count = j - i
    for k in (i + 1)..<j {
      items[k] = ""
    }
    items[i] = "′".repeat(count)
    i = j
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
  for text in items {
    guard text != "" else { continue }
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
/// Match directed boundaries before both become `‖`. For neutral `\Vert`
/// retain the existing nonempty-pair convention within each directed scope.
fn norm_pairs(nodes : Array[@katex.ParseNode]) -> Map[Int32, Int32] {
  let pairs = Map([])
  let opens : Array[(Int32, Int32?)] = []
  let mut neutral = None
  for i, node in nodes {
    match node {
      Atom(family=Mopen, text="\\lVert", ..) => {
        opens.push((i, neutral))
        neutral = None
      }
      Atom(family=Mclose, text="\\rVert", ..)
      | SupSub(base=Some(Atom(family=Mclose, text="\\rVert", ..)), ..) =>
        if opens.pop() is Some((open, previous)) {
          pairs[open] = i
          neutral = previous
        }
      TextOrd(text~, ..) if @backend.resolve_symbol(text) == "‖" =>
        match neutral {
          Some(open) if i > open + 1 => {
            pairs[open] = i
            neutral = None
          }
          None => neutral = Some(i)
          _ => ()
        }
      _ => ()
    }
  }
  pairs
}

///|
/// The `\not` macro contributes a bare combining long solidus (U+0338) through
/// its MathML branch. Mirroring the Unicode backend, the mark is folded into
/// the following single symbol as `cancel(...)` so the slash overlays it.
fn merge_not(items : Array[String]) -> Array[String] {
  for i in 0..<(items.length() - 1) {
    guard items[i] == "\u{0338}" else { continue }
    let next = items[i + 1]
    guard is_single_symbol(next) else { continue }
    items[i] = "cancel(\{next})"
    items[i + 1] = ""
  }
  items
}

///|
fn is_single_symbol(text : String) -> Bool {
  text.length() == 1 && !text.contains("\\")
}

///|
fn render_node(node : @katex.ParseNode, state : RenderState) -> String {
  match node {
    Internal(..) | EnvironmentEnd(..) => ""
    Raw(string~, ..) => render_symbol(string)
    ColorToken(color~, ..) => render_symbol(color)
    TextOrd(text~, ..)
    | MathOrd(text~, ..)
    | AccentToken(text~, ..)
    | OperatorToken(text~, ..)
    | Atom(text~, ..) => render_symbol(text, in_arg=state.in_arg)
    Spacing(text~, ..) => render_spacing(text)
    Size(value~, ..) => render_measurement(value)
    Url(url~, ..) => url
    Styling(body~, style~, ..) => render_styling(body, style, state)
    Sqrt(body~, index~, ..) => render_sqrt(index, body, state)
    Infix(..) => unsupported_comment("\\over/\\atop infix")
    GenFrac(numer~, denom~, has_bar_line~, left_delim~, right_delim~, ..) =>
      render_genfrac(numer, denom, has_bar_line, left_delim, right_delim, state)
    Text(body~, font~, ..) => render_text(body, font)
    Font(font~, body~, ..) => render_font(font, body, state)
    MClass(body~, ..) => render_nodes(body, state)
    Op(content~, ..) => render_op(content, state)
    OperatorName(body~, limits~, ..) => render_operatorname(body, limits, state)
    Overline(body~, ..) => math_fn("overline", render_node(body, state))
    Underline(body~, ..) => math_fn("underline", render_node(body, state))
    Smash(body~, ..) => render_node(body, state)
    Phantom(..) | VPhantom(..) => "#box(height: 0.5em)"
    Pmb(body~, ..) => render_nodes(body, state)
    VCenter(body~, ..) => render_node(body, state)
    Rule(width~, height~, ..) =>
      "#rect(width: \{render_measurement(width)}, height: \{render_measurement(height)})"
    RaiseBox(dy~, body~, ..) =>
      "#place(dy: \{render_measurement(dy)}, $\{render_node(body, state)}$)"
    // Preserve the body while explicitly marking unsupported mirroring.
    ReflectBox(body~, ..) =>
      "\{unsupported_comment("\\reflectbox/\\mathreflectbox mirroring")}\{render_node(body, state)}"
    HBox(body~, ..) => render_nodes(body, state)
    Lap(..) => unsupported_comment("\\llap/\\rlap/\\clap")
    MathChoice(display~, text~, script~, scriptscript~, ..) =>
      render_nodes(
        @backend.math_choice_variant(
          display,
          text,
          script,
          scriptscript,
          state.tex,
        ),
        state,
      )
    Sizing(size~, body~, ..) => render_sizing(size, body, state)
    HorizBrace(label~, base~, ..) => render_horiz_brace(label, base, state)
    XArrow(label~, body~, below~, ..) =>
      render_xarrow(label, body, below, state)
    AccentUnder(label~, base~, ..) => render_accent_under(label, base, state)
    DelimSizing(size~, delim~, ..) => render_delim_sizing(size, delim)
    LeftRightRight(delim~, ..) => render_delimiter(delim)
    LeftRight(body~, left~, right~, ..) =>
      render_left_right(body, left, right, state)
    Middle(delim~, ..) => math_fn("mid", render_delimiter(delim))
    Kern(dimension~, ..) => render_kern(dimension)
    Enclose(label~, body~, background_color~, border_color~, ..) =>
      render_enclose(label, body, background_color, border_color, state)
    Href(href~, body~, ..) =>
      "#link(\"\{escape_string(href)}\")[$\{render_nodes(body, state)}$]"
    Html(..) => unsupported_comment("\\htmlClass/\\htmlId")
    IncludeGraphics(width~, height~, src~, ..) =>
      "#image(\"\{escape_string(src)}\", width: \{render_measurement(width)}, height: \{render_measurement(height)})"
    // Equation numbering belongs to the enclosing equation, not this fragment.
    Tag(body~, ..) => render_nodes(body, state)
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
/// A `\sqrt` node renders as Typst `sqrt(...)`; with an index it becomes a
/// two-argument `root(index, body)`.
fn render_sqrt(
  index : @katex.ParseNode?,
  body : @katex.ParseNode,
  state : RenderState,
) -> String {
  let arg = { ..state, in_arg: true, }
  let radicand = render_node(body, arg)
  guard index is Some(index) else { return math_fn("sqrt", radicand) }
  let index_state = { ..arg, tex: ScriptScriptStyle, typst: ScriptScriptStyle, }
  "root(\{wrap_arg(render_node(index, index_state))}, \{wrap_arg(radicand)})"
}

///|
/// A single-argument Typst math function call.
fn math_fn(name : String, content : String) -> String {
  "\{name}(\{wrap_arg(content)})"
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
fn render_measurement(measurement : @katex.Measurement) -> String {
  guard @backend.em_value(measurement) is Some(em) && measurement.unit == "ex" else {
    return "\{measurement.number}\{measurement.unit}"
  }
  em_string(em)
}

///|
/// Formats an em-valued length, rounding to three decimals. Shared by the
/// `ex` and `mu` unit conversions.
fn em_string(em : Double) -> String {
  "\{(em * 1000.0).round() / 1000.0}em"
}

///|
/// Pass an already-rendered sequence as a single content argument without
/// introducing visible delimiters or a nested equation element.
fn wrap_arg(content : String) -> String {
  if contains_top_level_separator(content) {
    "#($\{content}$.body)"
  } else {
    content
  }
}

///|
fn contains_top_level_separator(text : String) -> Bool {
  contains_top_level_char(text, is_arg_separator)
}

///|
fn is_arg_separator(c : Char) -> Bool {
  c == ',' || c == ';' || c == ':'
}

///|
/// Scans `text` for a character satisfying `is_separator` outside of bracket
/// groups and quoted strings. Shared by the wrappers that decide whether an
/// argument needs visible grouping parentheses in Typst.
fn contains_top_level_char(
  text : String,
  is_separator : (Char) -> Bool,
) -> Bool {
  let mut depth = 0
  let mut in_string = false
  let mut escaped = false
  for c in text {
    if escaped {
      escaped = false
    } else if c == '\\' {
      escaped = true
    } else if c == '"' {
      in_string = !in_string
    } else if !in_string {
      if c == '(' || c == '[' || c == '{' {
        depth = depth + 1
      } else if c == ')' || c == ']' || c == '}' {
        depth = depth - 1
      } else if depth == 0 && is_separator(c) {
        return true
      }
    }
  }
  false
}

///|
fn unsupported_comment(reason : String) -> String {
  "/* unsupported: \{reason} */"
}
