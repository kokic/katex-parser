///|
fn Parser::consume_array_hlines(
  self : Parser,
) -> Array[Bool] raise ParseFailure {
  let lines : Array[Bool] = []
  self.consume_spaces()
  while self.fetch().text == "\\hline" || self.fetch().text == "\\hdashline" {
    let dashed = self.fetch().text == "\\hdashline"
    self.consume()
    lines.push(dashed)
    self.consume_spaces()
  }
  lines
}

///|
fn Parser::take_array_tag(
  self : Parser,
  auto_tag : Bool?,
) -> (Array[ParseNode]?, Bool) raise ParseFailure {
  guard auto_tag is Some(automatic) else { (None, false) }
  guard self.gullet.macros.get("\\df@tag") is Some(_) else { (None, automatic) }
  let tag = self.subparse([Token::make("\\df@tag")])
  self.gullet.macros.set("\\df@tag", None, global=true)
  (Some(tag), false)
}

///|
/// Records the tag of the finished row when the environment collects tags:
/// pushes the tag (or `None` when the row has no `\tag`) and whether the tag
/// was automatic.
fn Parser::push_array_tag(
  self : Parser,
  tags : Array[Array[ParseNode]?],
  auto_tags : Array[Bool],
  auto_tag : Bool?,
) -> Unit raise ParseFailure {
  let (tag, automatic) = self.take_array_tag(auto_tag)
  if auto_tag is Some(_) {
    tags.push(tag)
    auto_tags.push(automatic)
  }
}

///|
/// Parses the optional `[height]` argument that may follow `\\` in an array
/// row. A space before the bracket means the gap is absent.
fn Parser::parse_array_row_gap(
  self : Parser,
) -> Measurement? raise ParseFailure {
  if self.gullet.future().text == " " {
    None
  } else {
    match self.parse_size_group(true) {
      Some(Size(value~, ..)) => Some(value)
      Some(_) => raise InternalInvariant(message="Expected array row gap")
      None => None
    }
  }
}

///|
/// True when the current row already holds `max_columns` cells, so the next
/// `&` would exceed the declared column limit.
fn array_row_at_max(body : Array[Array[ParseNode]], max_columns : Int?) -> Bool {
  max_columns.map_or(false, maximum => {
    body.last() is Some(row) && row.length() >= maximum
  })
}

///|
/// Unwraps an array parse whose cleanup closes a cell group and an array
/// group, re-raising the first captured error.
fn unwrap_array_parse_result(
  result : Result[ParseNode, ParseFailure],
  close_cell : Result[Unit, ParseFailure],
  close_array : Result[Unit, ParseFailure],
) -> ParseNode raise ParseFailure {
  match (result, close_cell, close_array) {
    (Err(err), _, _) => raise err
    (_, Err(err), _) => raise err
    (_, _, Err(err)) => raise err
    (Ok(node), Ok(_), Ok(_)) => node
  }
}

///|
/// Parses an array environment body: cells of the current row accumulate
/// until `&`, `\\`, or `\end`; `\\` takes an optional `[gap]` and the
/// `\hline`/`\hdashline` rules that open the next row; `\end` closes the
/// array, collecting the row's `\tag` when `auto_tag` is set. Row gaps, tags,
/// and the per-row hline list are collected alongside the body, and the
/// hline list is padded so it has one entry per row boundary.
fn Parser::parse_array_environment(
  self : Parser,
  options : ArrayEnvironmentOptions,
) -> ParseNode raise ParseFailure {
  self.gullet.begin_group()
  self.gullet.macros.set("\\cr", Some(MacroDefinition::text("\\\\\\relax")))
  self.gullet.begin_group()
  let result : Result[ParseNode, ParseFailure] = capture_parse_result(() => {
    let body : Array[Array[ParseNode]] = [[]]
    let row_gaps : Array[Measurement?] = []
    let hlines_before_row : Array[Array[Bool]] = [self.consume_array_hlines()]
    let tags : Array[Array[ParseNode]?] = []
    let auto_tags : Array[Bool] = []
    for ;; {
      let cell_body = self.parse_expression(false, Some("\\\\"))
      let cell : ParseNode = Styling(
        mode=self.mode,
        body=[
          OrdGroup(mode=self.mode, loc=None, body=cell_body, semisimple=false),
        ],
        style=options.cell_style,
        reset_font=true,
      )
      self.gullet.end_group()
      self.gullet.begin_group()
      guard body.last() is Some(row) else {
        raise InternalInvariant(message="Missing array row")
      }
      row.push(cell)
      match self.fetch().text {
        "&" => {
          guard !array_row_at_max(body, options.max_columns) else {
            raise InvalidArgument(
              message="Too many tab characters: &",
              loc=None,
            )
          }
          self.consume()
        }
        "\\end" => {
          self.push_array_tag(tags, auto_tags, options.auto_tag)
          break
        }
        "\\\\" => {
          guard !options.single_row else {
            raise InvalidArgument(message="Expected \\end", loc=None)
          }
          self.consume()
          row_gaps.push(self.parse_array_row_gap())
          self.push_array_tag(tags, auto_tags, options.auto_tag)
          hlines_before_row.push(self.consume_array_hlines())
          body.push([])
        }
        token =>
          raise InvalidArgument(
            message="Expected & or \\\\ or \\end, got \{token}",
            loc=None,
          )
      }
    }
    if hlines_before_row.length() < body.length() + 1 {
      hlines_before_row.push([])
    }
    Array(
      mode=self.mode,
      body~,
      add_jot=options.add_jot,
      array_stretch=options.array_stretch,
      columns=options.columns,
      row_gaps~,
      hskip_before_and_after=options.hskip_before_and_after,
      hlines_before_row~,
      column_separation_type=options.column_separation_type,
      tags=if options.auto_tag is Some(_) { Some(tags) } else { None },
      auto_tags=if options.auto_tag is Some(_) { Some(auto_tags) } else { None },
      leqno=options.leqno,
    )
  })
  let close_cell : Result[Unit, ParseFailure] = capture_parse_result(() => {
    self.gullet.end_group()
  })
  let close_array : Result[Unit, ParseFailure] = capture_parse_result(() => {
    self.gullet.end_group()
  })
  unwrap_array_parse_result(result, close_cell, close_array)
}
