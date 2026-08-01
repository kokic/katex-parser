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
  let alignments : Array[String] = columns.fold(init=[], (acc, column) => {
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
  let lines : Array[String] = columns.fold(init=[], (acc, column) => {
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
