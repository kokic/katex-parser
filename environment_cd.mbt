///|
fn cd_cell(body : Array[ParseNode]) -> ParseNode {
  Styling(mode=Math, body~, style=DisplayStyle, reset_font=true)
}

///|
fn cd_arrow_character(node : ParseNode) -> String? {
  match node {
    MathOrd(text~, ..) | TextOrd(text~, ..) | Atom(text~, ..) => Some(text)
    _ => None
  }
}

///|
fn cd_label_end(node : ParseNode, end : String) -> Bool {
  match node {
    MathOrd(text~, ..) | Atom(text~, ..) => text == end
    _ => false
  }
}

///|
fn cd_empty_label() -> ParseNode {
  OrdGroup(mode=Math, loc=None, body=[], semisimple=false)
}

///|
fn cd_arrow(
  arrow : String,
  upper : ParseNode,
  lower : ParseNode,
) -> ParseNode raise ParseFailure {
  match arrow {
    ">" =>
      XArrow(mode=Math, label="\\\\cdrightarrow", body=upper, below=Some(lower))
    "<" =>
      XArrow(mode=Math, label="\\\\cdleftarrow", body=upper, below=Some(lower))
    "=" =>
      XArrow(
        mode=Math,
        label="\\\\cdlongequal",
        body=cd_empty_label(),
        below=None,
      )
    "|" => DelimSizing(mode=Math, size=2, mclass=Mord, delim="\\Vert")
    "." => TextOrd(mode=Math, loc=None, text=" ")
    "A" | "V" => {
      let direction = if arrow == "A" { "\\uparrow" } else { "\\downarrow" }
      CdParent(
        mode=Math,
        fragment=OrdGroup(
          mode=Math,
          loc=None,
          body=[
            CdLabel(mode=Math, side="left", label=upper),
            DelimSizing(mode=Math, size=2, mclass=Mord, delim=direction),
            CdLabel(mode=Math, side="right", label=lower),
          ],
          semisimple=false,
        ),
      )
    }
    _ =>
      raise InvalidArgument(
        message="Expected one of \"<>AV=|.\" after @",
        loc=None,
      )
  }
}

///|
fn cd_row(
  nodes : Array[ParseNode],
  even : Bool,
) -> Array[ParseNode] raise ParseFailure {
  let row : Array[ParseNode] = []
  let cell : Array[ParseNode] = []
  let mut index = 0
  while index < nodes.length() {
    let node = nodes[index]
    if node is TextOrd(text="@", ..) {
      row.push(cd_cell(cell))
      cell.clear()
      index = index + 1
      guard nodes.get(index) is Some(character_node) else {
        raise InvalidArgument(
          message="Expected one of \"<>AV=|.\" after @",
          loc=None,
        )
      }
      let arrow = match cd_arrow_character(character_node) {
        Some(value) => value
        None =>
          raise InvalidArgument(
            message="Expected one of \"<>AV=|.\" after @",
            loc=None,
          )
      }
      index = index + 1
      let labels : Array[ParseNode] = [cd_empty_label(), cd_empty_label()]
      if arrow == ">" || arrow == "<" || arrow == "A" || arrow == "V" {
        for label_index in 0..<2 {
          let label_body : Array[ParseNode] = []
          let mut complete = false
          while index < nodes.length() {
            let current = nodes[index]
            if cd_label_end(current, arrow) {
              complete = true
              index = index + 1
              break
            }
            if current is TextOrd(text="@", ..) {
              raise InvalidArgument(
                message="Missing a " +
                  arrow +
                  " character to complete a CD arrow.",
                loc=None,
              )
            }
            label_body.push(current)
            index = index + 1
          }
          guard complete else {
            raise InvalidArgument(
              message="Missing a " +
                arrow +
                " character to complete a CD arrow.",
              loc=None,
            )
          }
          labels[label_index] = OrdGroup(
            mode=Math,
            loc=None,
            body=label_body,
            semisimple=false,
          )
        }
      } else if arrow != "=" && arrow != "|" && arrow != "." {
        raise InvalidArgument(
          message="Expected one of \"<>AV=|.\" after @",
          loc=None,
        )
      }
      row.push(cd_cell([cd_arrow(arrow, labels[0], labels[1])]))
    } else {
      cell.push(node)
      index = index + 1
    }
  }
  if even {
    row.push(cd_cell(cell))
  } else if !row.is_empty() {
    let _ = row.remove(0)
  }
  row
}

///|
fn Parser::parse_cd_environment(self : Parser) -> ParseNode raise ParseFailure {
  self.gullet.begin_group()
  self.gullet.macros.set("\\cr", Some(MacroDefinition::text("\\\\\\relax")))
  self.gullet.begin_group()
  let result : Result[ParseNode, ParseFailure] = Ok(
    {
      let parsed_rows : Array[Array[ParseNode]] = [[]]
      for ;; {
        let part = self.parse_expression(false, Some("\\\\"))
        match parsed_rows.last() {
          Some(row) => row.append(part)
          None => raise InternalInvariant(message="Missing CD row")
        }
        match self.fetch().text {
          "&" => self.consume()
          "\\\\" => {
            self.consume()
            parsed_rows.push([])
          }
          "\\end" => break
          token =>
            raise InvalidArgument(
              message="Expected \\ or \\end, got " + token,
              loc=None,
            )
        }
      }
      if parsed_rows.last() is Some([]) {
        let _ = parsed_rows.pop()
      }
      let body : Array[Array[ParseNode]] = []
      for index, row in parsed_rows {
        body.push(cd_row(row, index % 2 == 0))
      }
      let count = match body.get(0) {
        Some(row) => row.length()
        None => 0
      }
      let columns : Array[ArrayColumn] = []
      for _ in 0..<count {
        columns.push(AlignColumn(alignment="c", pre_gap=0.25, post_gap=0.25))
      }
      let hlines_before_row : Array[Array[Bool]] = []
      let row_gap_count = body.length() + 1
      for _ in 0..<row_gap_count {
        hlines_before_row.push([])
      }
      Array(
        mode=Math,
        body~,
        add_jot=true,
        array_stretch=1.0,
        columns=Some(columns),
        row_gaps=[None],
        hskip_before_and_after=false,
        hlines_before_row~,
        column_separation_type=Some(CdSeparation),
        tags=None,
        auto_tags=None,
        leqno=false,
      )
    },
  ) catch {
    err => Err(err)
  }
  let close_cell : Result[Unit, ParseFailure] = Ok(self.gullet.end_group()) catch {
    err => Err(err)
  }
  let close_array : Result[Unit, ParseFailure] = Ok(self.gullet.end_group()) catch {
    err => Err(err)
  }
  match (result, close_cell, close_array) {
    (Err(err), _, _) => raise err
    (_, Err(err), _) => raise err
    (_, _, Err(err)) => raise err
    (Ok(node), Ok(_), Ok(_)) => node
  }
}

///|
fn cd_environment_handler(
  context : EnvironmentContext,
  _ : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  guard context.display_mode else {
    raise InvalidArgument(
      message="{CD} can be used only in display mode.",
      loc=None,
    )
  }
  (context.parse_cd)()
}
