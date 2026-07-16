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
fn Parser::parse_array_environment(
  self : Parser,
  options : ArrayEnvironmentOptions,
) -> ParseNode raise ParseFailure {
  self.gullet.begin_group()
  self.gullet.macros.set("\\cr", Some(MacroDefinition::text("\\\\\\relax")))
  self.gullet.begin_group()
  let result : Result[ParseNode, ParseFailure] = Ok(
    {
      let body : Array[Array[ParseNode]] = [[]]
      let row_gaps : Array[Measurement?] = []
      let hlines_before_row : Array[Array[Bool]] = [self.consume_array_hlines()]
      for ;; {
        let cell_body = self.parse_expression(false, Some("\\\\"))
        let cell : ParseNode = if options.display_cells {
          Styling(
            mode=self.mode,
            body=[
              OrdGroup(
                mode=self.mode,
                loc=None,
                body=cell_body,
                semisimple=false,
              ),
            ],
            style=DisplayStyle,
            reset_font=true,
          )
        } else {
          OrdGroup(mode=self.mode, loc=None, body=cell_body, semisimple=false)
        }
        self.gullet.end_group()
        self.gullet.begin_group()
        match body.last() {
          Some(row) => row.push(cell)
          None => raise InternalInvariant(message="Missing array row")
        }
        match self.fetch().text {
          "&" => self.consume()
          "\\end" => break
          "\\\\" => {
            self.consume()
            let gap = if self.gullet.future().text == " " {
              None
            } else {
              match self.parse_size_group(true) {
                Some(Size(value~, ..)) => Some(value)
                Some(_) =>
                  raise InternalInvariant(message="Expected array row gap")
                None => None
              }
            }
            row_gaps.push(gap)
            hlines_before_row.push(self.consume_array_hlines())
            body.push([])
          }
          token =>
            raise InvalidArgument(
              message="Expected & or \\\\ or \\end, got " + token,
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
        array_stretch=options.array_stretch,
        columns=options.columns,
        row_gaps~,
        hskip_before_and_after=options.hskip_before_and_after,
        hlines_before_row~,
        column_separation_type=None,
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
