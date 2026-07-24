///|
/// Renders parsed KaTeX nodes as Presentation MathML.
pub fn render(
  nodes : Array[@katex_parser.ParseNode],
  config? : RenderConfig = RenderConfig::default(),
) -> String {
  let state = {
    style: @katex_parser.StyleLevel::TextStyle,
    math_variant: None,
    text_family: "normal",
    text_bold: false,
    text_italic: false,
    color: None,
  }
  let body = make_row(render_expression(nodes, state))
  let semantic_children = match config.annotation {
    Some(source) =>
      [
        body,
        element("annotation", children=[text_node(source)], attributes=[
          ("encoding", "application/x-tex"),
        ]),
      ]
    None => [body]
  }
  let math_attributes = [
    ("xmlns", "http://www.w3.org/1998/Math/MathML"),
    ..if config.display_mode {
      [("display", "block")]
    },
  ]
  element(
    "math",
    children=[element("semantics", children=semantic_children)],
    attributes=math_attributes,
  ).to_markup()
}

///|
fn render_expression(
  nodes : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> Array[MathMlNode] {
  combine_expression(nodes.map(node => render_node(node, state)))
}

///|
fn render_group(
  node : @katex_parser.ParseNode,
  state : RenderState,
) -> MathMlNode {
  render_node(node, state)
}

///|
fn render_node(
  node : @katex_parser.ParseNode,
  state : RenderState,
) -> MathMlNode {
  match node {
    Internal(..) | EnvironmentEnd(..) => element("mrow")
    Raw(string~, ..) => text_token(string, Text, state)
    ColorToken(color~, ..) => text_token(color, Text, state)
    AccentToken(text~, ..) | OperatorToken(text~, ..) =>
      token("mo", text, state)
    MathOrd(text~, ..) => token("mi", text, state)
    TextOrd(text~, mode~, ..) => text_ordinary(text, mode, state)
    Atom(text~, family~, ..) => render_atom(text, family, state)
    Spacing(text~, ..) => render_spacing(text)
    Size(value~, ..) =>
      element("mspace", attributes=[("width", measurement(value))])
    Url(url~, ..) => text_token(url, Text, state)
    Styling(body~, style~, reset_font~, ..) =>
      render_styling(body, style, reset_font, state)
    Text(body~, font~, ..) =>
      make_row(render_expression(body, text_state(font, state)))
    MClass(body~, mclass~, is_character_box~, ..) =>
      render_mclass(body, mclass, is_character_box, state)
    HBox(body~, ..) =>
      element(
        "mrow",
        children=render_expression(body, { ..state, math_variant: None }),
      )
    Sizing(body~, size~, ..) =>
      element("mstyle", children=render_expression(body, state), attributes=[
        ("mathsize", size_multiplier(size)),
      ])
    Color(body~, color~, ..) =>
      element(
        "mstyle",
        children=render_expression(body, { ..state, color: Some(color) }),
        attributes=[("mathcolor", color)],
      )
    Href(body~, href~, ..) =>
      make_row(render_expression(body, state)).with_attribute("href", href)
    Html(body~, ..) | OrdGroup(body~, ..) =>
      make_row(render_expression(body, state))
    Sqrt(body~, index=None, ..) =>
      element("msqrt", children=[render_group(body, state)])
    Sqrt(body~, index=Some(index), ..) =>
      element("mroot", children=[
        render_group(body, state),
        render_group(index, state),
      ])
    Infix(replace_with~, ..) => token("mo", replace_with, state)
    GenFrac(
      numer~,
      denom~,
      has_bar_line~,
      bar_size~,
      left_delim~,
      right_delim~,
      ..
    ) =>
      render_fraction(
        numer, denom, has_bar_line, bar_size, left_delim, right_delim, state,
      )
    Font(font~, body~, ..) =>
      render_group(body, { ..state, math_variant: math_variant(font) })
    Op(content~, ..) => render_operator(content, state)
    OperatorName(body~, ..) => render_operator_name(body, state)
    Overline(body~, ..) => accent_over("mover", body, "‾", "accent", state)
    Underline(body~, ..) =>
      accent_over("munder", body, "‾", "accentunder", state)
    Smash(body~, smash_height~, smash_depth~, ..) => {
      let attrs = [
        ..if smash_height {
          [("height", "0px")]
        },
        ..if smash_depth {
          [("depth", "0px")]
        },
      ]
      element("mpadded", children=[render_group(body, state)], attributes=attrs)
    }
    VPhantom(body~, ..) =>
      element(
        "mpadded",
        children=[element("mphantom", children=[render_group(body, state)])],
        attributes=[("width", "0px")],
      )
    VCenter(body~, ..) =>
      element("mrow", children=[
        element("mpadded", children=[render_group(body, state)], attributes=[
          ("class", "vcenter"),
        ]),
      ])
    RaiseBox(dy~, body~, ..) =>
      element("mpadded", children=[render_group(body, state)], attributes=[
        ("voffset", measurement(dy)),
      ])
    Lap(alignment~, body~, ..) => render_lap(alignment, body, state)
    CdParent(fragment~, ..) =>
      element("mrow", children=[render_group(fragment, state)])
    Phantom(body~, ..) =>
      element("mphantom", children=render_expression(body, state))
    Pmb(body~, ..) =>
      element("mstyle", children=render_expression(body, state), attributes=[
        ("style", "text-shadow: 0.02em 0.01em 0.04px"),
      ])
    Rule(width~, height~, shift~, ..) =>
      render_rule(width, height, shift, state)
    MathChoice(display~, text~, script~, scriptscript~, ..) =>
      render_math_choice(display, text, script, scriptscript, state)
    HorizBrace(label~, is_over~, base~, ..) =>
      element(if is_over { "mover" } else { "munder" }, children=[
        render_group(base, state),
        stretchy(label),
      ])
    XArrow(label~, body~, below~, ..) =>
      render_xarrow(label, body, below, state)
    AccentUnder(label~, base~, ..) =>
      element("munder", children=[render_group(base, state), stretchy(label)], attributes=[
        ("accentunder", "true"),
      ])
    DelimSizing(delim~, mclass~, size~, ..) =>
      render_sized_delim(delim, mclass, size)
    LeftRightRight(delim~, color~, ..) => render_fence(delim, color)
    Middle(delim~, ..) => render_middle(delim)
    LeftRight(body~, left~, right~, right_color~, ..) =>
      render_left_right(body, left, right, right_color, state)
    Kern(dimension~, ..) =>
      element("mspace", attributes=[("width", measurement(dimension))])
    Enclose(label~, body~, background_color~, border_color~, ..) =>
      render_enclose(label, body, background_color, border_color, state)
    IncludeGraphics(alt~, width~, height~, totalheight~, src~, ..) =>
      render_image(alt, width, height, totalheight, src)
    Tag(body~, tag~, ..) => render_tag(body, tag, state)
    Array(
      body~,
      columns~,
      array_stretch~,
      row_gaps~,
      hlines_before_row~,
      column_separation_type~,
      tags~,
      leqno~,
      ..
    ) =>
      render_array(
        body, columns, array_stretch, row_gaps, hlines_before_row, column_separation_type,
        tags, leqno, state,
      )
    CdLabel(side~, label~, ..) => render_cd_label(side, label, state)
    Cr(new_line~, size~, ..) => render_cr(new_line, size)
    HtmlMathML(mathml~, ..) => make_row(render_expression(mathml, state))
    SupSub(base~, sup~, sub~, ..) => render_sup_sub(base, sup, sub, state)
    Accent(label~, is_stretchy~, base~, ..) =>
      render_accent(label, is_stretchy, base, state)
    Verb(body~, star~, ..) =>
      element("mtext", children=[text_node(verb_text(body, star))], attributes=[
        ("mathvariant", "monospace"),
      ])
  }
}

///|
fn token(kind : String, value : String, state : RenderState) -> MathMlNode {
  let attrs = [
    ..state.math_variant.map_or([], variant => [("mathvariant", variant)]),
    ..state.color.map_or([], color => [("mathcolor", color)]),
  ]
  element(kind, children=[text_node(symbol(value))], attributes=attrs)
}

///|
fn text_token(
  value : String,
  mode : @katex_parser.Mode,
  state : RenderState,
) -> MathMlNode {
  let kind = match mode {
    Text => "mtext"
    Math => "mi"
  }
  let attrs = text_attributes(kind, state)
  element(kind, children=[text_node(symbol(value))], attributes=attrs)
}

///|
fn text_ordinary(
  value : String,
  mode : @katex_parser.Mode,
  state : RenderState,
) -> MathMlNode {
  let kind = match mode {
    Text => "mtext"
    Math =>
      if contains_ascii_digit(value) {
        "mn"
      } else if value == "\\prime" {
        "mo"
      } else {
        "mi"
      }
  }
  element(
    kind,
    children=[text_node(symbol(value))],
    attributes=text_attributes(kind, state),
  )
}

///|
fn text_attributes(
  kind : String,
  state : RenderState,
) -> Array[(String, String)] {
  let variant = if kind == "mtext" {
    text_variant(state)
  } else {
    state.math_variant
  }
  [
    ..variant.map_or([], value => [("mathvariant", value)]),
    ..state.color.map_or([], color => [("mathcolor", color)]),
  ]
}

///|
fn render_atom(
  text : String,
  family : @katex_parser.AtomFamily,
  state : RenderState,
) -> MathMlNode {
  let attrs = [
    ..match family {
      Mpunct => [("separator", "true")]
      Mopen | Mclose => [("stretchy", "false")]
      _ => []
    },
    ..match state.math_variant {
      Some("bold-italic") if family is Mbin => [("mathvariant", "bold-italic")]
      _ => []
    },
  ]
  element("mo", children=[text_node(symbol(text))], attributes=attrs)
}

///|
fn render_spacing(value : String) -> MathMlNode {
  match value {
    " " | "\\ " | "~" | "\\space" | "\\nobreakspace" =>
      element("mtext", children=[text_node(" ")])
    "\\nobreak" | "\\allowbreak" => element("mspace")
    _ => element("mspace")
  }
}

///|
fn render_styling(
  body : Array[@katex_parser.ParseNode],
  style : @katex_parser.StyleLevel,
  reset_font : Bool,
  state : RenderState,
) -> MathMlNode {
  let child_state = if reset_font {
    { ..state, style, math_variant: None }
  } else {
    { ..state, style, }
  }
  let (scriptlevel, displaystyle) = match style {
    DisplayStyle => ("0", "true")
    TextStyle => ("0", "false")
    ScriptStyle => ("1", "false")
    ScriptScriptStyle => ("2", "false")
  }
  element("mstyle", children=render_expression(body, child_state), attributes=[
    ("scriptlevel", scriptlevel),
    ("displaystyle", displaystyle),
  ])
}

///|
fn render_mclass(
  body : Array[@katex_parser.ParseNode],
  mclass : @katex_parser.AtomFamily,
  _is_character_box : Bool,
  state : RenderState,
) -> MathMlNode {
  let children = render_expression(body, state)
  match mclass {
    Minner => element("mpadded", children~)
    Mord => element("mi", children~)
    Mbin =>
      element("mo", children~, attributes=[
        ("lspace", "0.22em"),
        ("rspace", "0.22em"),
      ])
    Mpunct =>
      element("mo", children~, attributes=[
        ("lspace", "0em"),
        ("rspace", "0.17em"),
      ])
    Mopen | Mclose =>
      element("mo", children~, attributes=[("lspace", "0em"), ("rspace", "0em")])
    Mop | Mrel => element("mo", children~)
  }
}

///|
fn render_fraction(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  has_bar_line : Bool,
  bar_size : @katex_parser.Measurement?,
  left : String?,
  right : String?,
  state : RenderState,
) -> MathMlNode {
  let attrs = if !has_bar_line {
    [("linethickness", "0px")]
  } else {
    bar_size.map_or([], size => [("linethickness", measurement(size))])
  }
  let fraction = element(
    "mfrac",
    children=[render_group(numer, state), render_group(denom, state)],
    attributes=attrs,
  )
  match (left, right) {
    (None, None) => fraction
    _ => {
      let left_children = left.map_or([], delim => [render_fence(delim, None)])
      let right_children = right.map_or([], delim => [render_fence(delim, None)])
      let children = left_children + [fraction] + right_children
      make_row(children)
    }
  }
}

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
fn render_lap(
  alignment : @katex_parser.LapAlignment,
  body : @katex_parser.ParseNode,
  state : RenderState,
) -> MathMlNode {
  let attrs = match alignment {
    LLap => [("lspace", "-1width"), ("width", "0px")]
    CLap => [("lspace", "-0.5width"), ("width", "0px")]
    RLap => [("width", "0px")]
  }
  element("mpadded", children=[render_group(body, state)], attributes=attrs)
}

///|
fn render_rule(
  width : @katex_parser.Measurement,
  height : @katex_parser.Measurement,
  shift : @katex_parser.Measurement?,
  state : RenderState,
) -> MathMlNode {
  let background = state.color.unwrap_or("black")
  let rule = element("mspace", attributes=[
    ("mathbackground", background),
    ("width", measurement(width)),
    ("height", measurement(height)),
  ])
  let attrs = shift.map_or([], value => [("voffset", measurement(value))])
  element("mpadded", children=[rule], attributes=attrs)
}

///|
fn render_math_choice(
  display : Array[@katex_parser.ParseNode],
  text : Array[@katex_parser.ParseNode],
  script : Array[@katex_parser.ParseNode],
  scriptscript : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> MathMlNode {
  let selected = match state.style {
    DisplayStyle => display
    TextStyle => text
    ScriptStyle => script
    ScriptScriptStyle => scriptscript
  }
  make_row(render_expression(selected, state))
}

///|
fn render_xarrow(
  label : String,
  body : @katex_parser.ParseNode,
  below : @katex_parser.ParseNode?,
  state : RenderState,
) -> MathMlNode {
  let arrow = stretchy(label).with_attribute(
    "minsize",
    if label.has_prefix("\\x") {
      "1.75em"
    } else {
      "3em"
    },
  )
  match below {
    Some(lower) =>
      element("munderover", children=[
        arrow,
        element("mpadded", children=[render_group(lower, state)], attributes=[
          ("width", "+0.6em"),
          ("lspace", "0.3em"),
        ]),
        element("mpadded", children=[render_group(body, state)], attributes=[
          ("width", "+0.6em"),
          ("lspace", "0.3em"),
        ]),
      ])
    None =>
      element("mover", children=[
        arrow,
        element("mpadded", children=[render_group(body, state)], attributes=[
          ("width", "+0.6em"),
          ("lspace", "0.3em"),
        ]),
      ])
  }
}

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

///|
fn render_enclose(
  label : String,
  body : @katex_parser.ParseNode,
  background : String?,
  border : String?,
  state : RenderState,
) -> MathMlNode {
  let notation = match label {
    "\\cancel" => Some("updiagonalstrike")
    "\\bcancel" => Some("downdiagonalstrike")
    "\\xcancel" => Some("updiagonalstrike downdiagonalstrike")
    "\\phase" => Some("phasorangle")
    "\\sout" => Some("horizontalstrike")
    "\\fbox" => Some("box")
    "\\angl" => Some("actuarial")
    _ => None
  }
  let attrs = [
    ..notation.map_or([], value => [("notation", value)]),
    ..background.map_or([], value => [("mathbackground", value)]),
    ..border.map_or([], value => [("style", "border: 0.04em solid \{value}")]),
  ]
  element("menclose", children=[render_group(body, state)], attributes=attrs)
}

///|
fn render_image(
  alt : String,
  width : @katex_parser.Measurement,
  height : @katex_parser.Measurement,
  totalheight : @katex_parser.Measurement,
  src : String,
) -> MathMlNode {
  let attrs = [
    ("alt", alt),
    (
      "height",
      measurement(if totalheight.number > 0 { totalheight } else { height }),
    ),
    ("src", src),
    ..if width.number > 0 {
      [("width", measurement(width))]
    },
  ]
  element("mglyph", attributes=attrs)
}

///|
fn render_tag(
  body : Array[@katex_parser.ParseNode],
  tag : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> MathMlNode {
  let pad = element("mtd", attributes=[("width", "50%")])
  element(
    "mtable",
    children=[
      element("mtr", children=[
        pad,
        element("mtd", children=[make_row(render_expression(body, state))]),
        pad,
        element("mtd", children=[make_row(render_expression(tag, state))]),
      ]),
    ],
    attributes=[("width", "100%")],
  )
}

///|
fn render_array(
  body : Array[Array[@katex_parser.ParseNode]],
  columns : Array[@katex_parser.ArrayColumn]?,
  array_stretch : Double,
  _row_gaps : Array[@katex_parser.Measurement?],
  hlines : Array[Array[Bool]],
  separation : @katex_parser.ColumnSeparationType?,
  tags : Array[Array[@katex_parser.ParseNode]?]?,
  _leqno : Bool,
  state : RenderState,
) -> MathMlNode {
  let rows = Array::makei(body.length(), i => {
    let row = body[i].map(cell => {
      element("mtd", children=[render_group(cell, state)])
    })
    match tags {
      Some(all_tags) =>
        match all_tags[i] {
          Some(tag) =>
            element(
              "mlabeledtr",
              children=[
                  element("mtd", children=[
                    make_row(render_expression(tag, state)),
                  ]),
                ] +
                row,
            )
          None => element("mtr", children=row)
        }
      None => element("mtr", children=row)
    }
  })
  let row_spacing = if array_stretch == 1.0 {
    "0.16em"
  } else {
    (0.16 + array_stretch - 1).to_string() + "em"
  }
  let attrs = [
    ("rowspacing", row_spacing),
    ("columnspacing", column_spacing(separation)),
    ..columns.map_or([], spec => array_column_attributes(spec)),
    ..row_lines(hlines).map_or([], lines => [("rowlines", lines)]),
  ]
  element("mtable", children=rows, attributes=attrs)
}

///|
fn row_lines(hlines : Array[Array[Bool]]) -> String? {
  guard hlines.length() > 2 else { None }
  let lines = hlines[1:hlines.length() - 1].map(line => {
    if line.length() == 0 {
      "none"
    } else if line[0] {
      "dashed"
    } else {
      "solid"
    }
  })
  if lines.any(line => line != "none") {
    Some(lines.join(" "))
  } else {
    None
  }
}

///|
fn array_column_attributes(
  columns : Array[@katex_parser.ArrayColumn],
) -> Array[(String, String)] {
  let alignments : Array[String] = columns.fold(init=[], fn(acc, column) {
    match column {
      AlignColumn(alignment~, ..) => {
        let value = match alignment {
          "l" => "left"
          "r" => "right"
          _ => "center"
        }
        acc + [value]
      }
      SeparatorColumn(..) => acc
    }
  })
  let lines : Array[String] = columns.fold(init=[], fn(acc, column) {
    match column {
      SeparatorColumn(separator~) =>
        acc + [if separator == ":" { "dashed" } else { "solid" }]
      _ => acc
    }
  })
  [
    ..if alignments.length() > 0 {
      [("columnalign", alignments.join(" "))]
    },
    ..if lines.length() > 0 {
      [("columnlines", lines.join(" "))]
    },
  ]
}

///|
fn column_spacing(kind : @katex_parser.ColumnSeparationType?) -> String {
  match kind {
    Some(AlignSeparation) => "0em 1em"
    Some(AlignAtSeparation) | Some(GatherSeparation) => "0em"
    Some(SmallSeparation) => "0.2778em"
    Some(CdSeparation) => "0.5em"
    None => "1em"
  }
}

///|
fn render_cd_label(
  side : String,
  label : @katex_parser.ParseNode,
  state : RenderState,
) -> MathMlNode {
  let attrs = [
    ("width", "0"),
    ("voffset", "0.7em"),
    ..if side == "left" {
      [("lspace", "-1width")]
    },
  ]
  element(
    "mstyle",
    children=[
      element(
        "mpadded",
        children=[element("mrow", children=[render_group(label, state)])],
        attributes=attrs,
      ),
    ],
    attributes=[("displaystyle", "false"), ("scriptlevel", "1")],
  )
}

///|
fn render_cr(new_line : Bool, size : @katex_parser.Measurement?) -> MathMlNode {
  let attrs = [
    ..if new_line {
      [("linebreak", "newline")]
    },
    ..size.map_or([], value => [("height", measurement(value))]),
  ]
  element("mspace", attributes=attrs)
}

///|
fn render_sup_sub(
  base : @katex_parser.ParseNode?,
  sup : @katex_parser.ParseNode?,
  sub : @katex_parser.ParseNode?,
  state : RenderState,
) -> MathMlNode {
  let limits = operator_uses_limits(base, state)
  let base = base.map_or(element("mrow"), value => render_group(value, state))
  let script_style = match state.style {
    DisplayStyle | TextStyle => @katex_parser.StyleLevel::ScriptStyle
    ScriptStyle | ScriptScriptStyle =>
      @katex_parser.StyleLevel::ScriptScriptStyle
  }
  let script_state = { ..state, style: script_style }
  match (sub, sup) {
    (Some(lower), Some(upper)) =>
      element(if limits { "munderover" } else { "msubsup" }, children=[
        base,
        render_group(lower, script_state),
        render_group(upper, script_state),
      ])
    (Some(lower), None) =>
      element(if limits { "munder" } else { "msub" }, children=[
        base,
        render_group(lower, script_state),
      ])
    (None, Some(upper)) =>
      element(if limits { "mover" } else { "msup" }, children=[
        base,
        render_group(upper, script_state),
      ])
    (None, None) => base
  }
}

///|
fn operator_uses_limits(
  base : @katex_parser.ParseNode?,
  state : RenderState,
) -> Bool {
  match base {
    Some(Op(limits=true, always_handle_sup_sub~, ..)) =>
      state.style is DisplayStyle || always_handle_sup_sub
    Some(OperatorName(limits=true, always_handle_sup_sub~, ..)) =>
      state.style is DisplayStyle || always_handle_sup_sub
    _ => false
  }
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

///|
fn math_variant(font : String) -> String? {
  match font {
    "mathit" => Some("italic")
    "boldsymbol" => Some("bold-italic")
    "mathbf" => Some("bold")
    "mathbb" => Some("double-struck")
    "mathsfit" => Some("sans-serif-italic")
    "mathfrak" => Some("fraktur")
    "mathscr" | "mathcal" => Some("script")
    "mathsf" => Some("sans-serif")
    "mathtt" => Some("monospace")
    "mathrm" => Some("normal")
    _ => None
  }
}

///|
fn text_state(font : String, state : RenderState) -> RenderState {
  match font {
    "\\textrm" | "\\textnormal" => { ..state, text_family: "normal" }
    "\\textsf" => { ..state, text_family: "sans-serif" }
    "\\texttt" => { ..state, text_family: "monospace" }
    "\\textbf" => { ..state, text_bold: true }
    "\\textmd" => { ..state, text_bold: false }
    "\\textit" => { ..state, text_italic: true }
    "\\textup" => { ..state, text_italic: false }
    "\\emph" => { ..state, text_italic: !state.text_italic }
    _ => state
  }
}

///|
fn text_variant(state : RenderState) -> String? {
  if state.text_family == "monospace" {
    Some("monospace")
  } else if state.text_family == "sans-serif" &&
    state.text_bold &&
    state.text_italic {
    Some("sans-serif-bold-italic")
  } else if state.text_family == "sans-serif" && state.text_bold {
    Some("bold-sans-serif")
  } else if state.text_family == "sans-serif" && state.text_italic {
    Some("sans-serif-italic")
  } else if state.text_family == "sans-serif" {
    Some("sans-serif")
  } else if state.text_bold && state.text_italic {
    Some("bold-italic")
  } else if state.text_bold {
    Some("bold")
  } else if state.text_italic {
    Some("italic")
  } else {
    None
  }
}

///|
fn stretchy(label : String) -> MathMlNode {
  let value = match label {
    "\\widehat" => "^"
    "\\widecheck" => "ˇ"
    "\\widetilde" | "\\utilde" => "~"
    "\\overleftarrow" | "\\underleftarrow" | "\\xleftarrow" | "\\cdleftarrow" =>
      "←"
    "\\overrightarrow"
    | "\\underrightarrow"
    | "\\xrightarrow"
    | "\\cdrightarrow" => "→"
    "\\overbrace" => "⏞"
    "\\underbrace" => "⏟"
    "\\overbracket" => "⎴"
    "\\underbracket" => "⎵"
    "\\overleftrightarrow" | "\\underleftrightarrow" | "\\xleftrightarrow" =>
      "↔"
    "\\Overrightarrow" | "\\xRightarrow" => "⇒"
    "\\xLeftarrow" => "⇐"
    "\\xLeftrightarrow" => "⇔"
    "\\xmapsto" => "↦"
    "\\xlongequal" | "\\cdlongequal" => "="
    _ => symbol(label)
  }
  element("mo", children=[text_node(value)], attributes=[("stretchy", "true")])
}

///|
fn measurement(value : @katex_parser.Measurement) -> String {
  if value.unit == "mu" {
    (value.number / 18.0).to_string() + "em"
  } else {
    value.number.to_string() + value.unit
  }
}

///|
fn size_multiplier(size : Int) -> String {
  let values : Array[String] = [
    "0.5em", "0.6em", "0.7em", "0.8em", "0.9em", "1em", "1.2em", "1.44em", "1.728em",
    "2.074em", "2.488em",
  ]
  if size >= 1 && size <= values.length() {
    values[size - 1]
  } else {
    "1em"
  }
}

///|
fn symbol(value : String) -> String {
  @katex_parser.unicode_symbol(value).unwrap_or(value)
}

///|
fn strip_command(value : String) -> String {
  value.replace(old="\\", new="")
}

///|
fn contains_ascii_digit(value : String) -> Bool {
  for character in value {
    guard character >= '0' && character <= '9' else { continue }
    return true
  }
  false
}

///|
fn verb_text(value : String, star : Bool) -> String {
  value.replace_all(old=" ", new=if star { "␣" } else { " " })
}
