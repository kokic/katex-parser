///|
fn render_array(
  node : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  match node {
    Array(body~, columns~, hlines_before_row~, column_separation_type~, ..) => {
      if hlines_before_row.any(row => row.length() > 0) {
        render_array_table(body, columns, hlines_before_row, state)
      } else {
        match column_separation_type {
          None => render_mat_body(body, columns, None, state)
          Some(@katex_parser.ColumnSeparationType::AlignSeparation) =>
            render_aligned(body, state)
          Some(
            @katex_parser.ColumnSeparationType::AlignAtSeparation,
          ) =>
            unsupported_comment("alignat")
          Some(@katex_parser.ColumnSeparationType::GatherSeparation) =>
            unsupported_comment("gathered")
          Some(@katex_parser.ColumnSeparationType::SmallSeparation) =>
            render_substack(body, columns, state)
          Some(@katex_parser.ColumnSeparationType::CdSeparation) =>
            unsupported_comment("cd")
        }
      }
    }
    _ => ""
  }
}

///|
fn render_leftright_array(
  array : @katex_parser.ParseNode,
  left : String,
  right : String,
  state : RenderState,
) -> String {
  match array {
    Array(
      body~,
      columns~,
      hlines_before_row~,
      column_separation_type~,
      ..
    ) =>
      if hlines_before_row.any(row => row.length() > 0) {
        let content = render_array_table(body, columns, hlines_before_row, state)
        wrap_lr(content, left, right)
      } else if column_separation_type is None &&
        is_left_brace(left) &&
        columns.map_or(false, all_l) {
        render_cases(body, state)
      } else if column_separation_type is None {
        if columns.map_or(false, contains_separator) {
          let content = render_array_table(body, columns, hlines_before_row, state)
          wrap_lr(content, left, right)
        } else {
          let delim = match (left, right) {
            ("(", ")") => Some("\"(\"")
            ("[", "]") => Some("\"[\"")
            ("\\{", "\\}") | ("{", "}") => Some("\"{\"")
            ("|", "|") => Some("\"|\"")
            ("\\|", "\\|") | ("‖", "‖") => Some("\"‖\"")
            _ =>
              // Mismatched or uncommon delimiter pairs: pass an explicit pair.
              Some("#(\"{left}\", \"{right}\")")
          }
          render_mat_body(body, columns, delim, state)
        }
      } else {
        match column_separation_type {
          Some(@katex_parser.ColumnSeparationType::SmallSeparation) => {
            // `\left( \substack{...} \right)`: the stack has no delimiter of
            // its own, so the surrounding `lr` is preserved.
            let content = render_substack(body, columns, state)
            wrap_lr(content, left, right)
          }
          _ => render_array(array, state)
        }
      }
    _ => ""
  }
}

///|
fn is_left_brace(left : String) -> Bool {
  left == "\\{" || left == "{" || left == "\\lbrace"
}

///|
fn all_l(columns : Array[@katex_parser.ArrayColumn]) -> Bool {
  columns.all(column =>
    match column {
      AlignColumn(alignment~, ..) => alignment == "l"
      _ => false
    }
  )
}

///|
fn render_mat_body(
  body : Array[Array[@katex_parser.ParseNode]],
  columns : Array[@katex_parser.ArrayColumn]?,
  delim : String?,
  state : RenderState,
) -> String {
  if columns.map_or(false, contains_separator) {
    render_array_table(body, columns, [], state)
  } else {
    let rows = body.map(row => render_mat_row(row, state)).join("; ")
    let delim_arg = delim.map_or("", d => ", delim: \{d}")
    let align_arg = columns
      .map(column_align_args)
      .bind(x => x)
      .unwrap_or("")
    if rows == "" {
      unsupported_comment("empty array")
    } else {
      "mat(\{rows}\{delim_arg}\{align_arg})"
    }
  }
}

///|
/// `\substack` expands to the one-column `subarray` environment; `smallmatrix`
/// (also `SmallSeparation`) has one column per row. There is no 0.15 `stack`
/// math function, so a single-column array is emitted as `mat(...)` with
/// `;`-separated rows, which renders as a compact centered stack. A
/// multi-column `smallmatrix` stays unsupported.
fn render_substack(
  body : Array[Array[@katex_parser.ParseNode]],
  columns : Array[@katex_parser.ArrayColumn]?,
  state : RenderState,
) -> String {
  match columns {
    None => render_stack_rows(body, state)
    Some(cols) =>
      if cols.length() <= 1 && cols.all(col => col is AlignColumn(..)) {
        render_stack_rows(body, state)
      } else {
        unsupported_comment("smallmatrix")
      }
  }
}

///|
fn render_stack_rows(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  let rows = body
    .map(row => row.map(cell => render_cell(cell, state)).join(", "))
    .join("; ")
  if rows == "" {
    unsupported_comment("empty array")
  } else {
    "mat(\{rows})"
  }
}

///|
/// Typst `mat` only supports a single uniform alignment, so per-column specs
/// are emitted only when every column agrees.
fn column_align_args(
  columns : Array[@katex_parser.ArrayColumn],
) -> String? {
  let aligns : Array[String] = columns.map(column =>
    match column {
      AlignColumn(alignment~, ..) =>
        match alignment {
          "l" => "left"
          "r" => "right"
          _ => "center"
        }
      _ => "center"
    }
  )
  let mut uniform = true
  for i in 1 ..< aligns.length() {
    if aligns[i] != aligns[0] {
      uniform = false
    }
  }
  if uniform && aligns[0] != "center" {
    Some(", align: #\{aligns[0]}")
  } else {
    None
  }
}

///|
fn contains_separator(columns : Array[@katex_parser.ArrayColumn]) -> Bool {
  columns.any(column => column is SeparatorColumn(..))
}

///|
/// Emits an array with horizontal lines or `|` column separators as a Typst
/// `#table(...)`: cells are `[$...$]` content, `table.hline()` draws the
/// `\hline`/`\hdashline` marks (dashed for the latter), and `table.vline()`
/// draws the separator columns. Vlines are written in every row — Typst
/// merges coincident segments, so they render as one full-height line.
fn render_array_table(
  body : Array[Array[@katex_parser.ParseNode]],
  columns : Array[@katex_parser.ArrayColumn]?,
  hlines_before_row : Array[Array[Bool]],
  state : RenderState,
) -> String {
  let ncols = match columns {
    Some(cols) =>
      cols.filter_map(col =>
        match col {
          AlignColumn(..) => Some(1)
          _ => None
        }
      ).length()
    None =>
      if body.length() > 0 { body[0].length() } else { 0 }
  }
  let vline_boundaries : Set[Int] = Set([])
  let aligns : Array[String] = []
  match columns {
    Some(cols) =>
      for col in cols {
        match col {
          AlignColumn(alignment~, ..) =>
            aligns.push(align_name(alignment))
          SeparatorColumn(..) => vline_boundaries.add(aligns.length())
        }
      }
    None => ()
  }
  let lines : Array[String] = [
    "#table(",
    "  columns: \{ncols},",
    "  align: \{render_table_align(aligns)},",
    "  stroke: none,",
  ]
  for i in 0 ..< body.length() {
    match hlines_before_row.get(i) {
      Some(row_lines) if row_lines.length() > 0 =>
        lines.push("  \{render_table_hline(row_lines)},")
      _ => ()
    }
    lines.push(
      "  \{table_row(body[i], vline_boundaries, ncols, state).join(", ")},",
    )
  }
  match hlines_before_row.get(body.length()) {
    Some(row_lines) if row_lines.length() > 0 =>
      lines.push("  \{render_table_hline(row_lines)},")
    _ => ()
  }
  lines.push(")")
  lines.join("\n")
}

///|
fn table_row(
  row : Array[@katex_parser.ParseNode],
  vline_boundaries : Set[Int],
  ncols : Int,
  state : RenderState,
) -> Array[String] {
  let cells : Array[String] = []
  for j in 0 ..< row.length() {
    if vline_boundaries.contains(j) {
      cells.push("table.vline(), [$\{render_cell(row[j], state)}$]")
    } else {
      cells.push("[$\{render_cell(row[j], state)}$]")
    }
  }
  if vline_boundaries.contains(ncols) {
    cells.push("table.vline()")
  }
  cells
}

///|
fn align_name(alignment : String) -> String {
  match alignment {
    "l" => "left"
    "r" => "right"
    _ => "center"
  }
}

///|
fn render_table_align(aligns : Array[String]) -> String {
  if aligns.all(a => a == "center") {
    "center"
  } else {
    "(\{aligns.join(", ")})"
  }
}

///|
fn render_table_hline(row_lines : Array[Bool]) -> String {
  if row_lines.any(line => line) {
    "table.hline(stroke: (thickness: 0.5pt, dash: (2pt, 1pt)))"
  } else {
    "table.hline()"
  }
}

///|
fn render_mat_row(
  row : Array[@katex_parser.ParseNode],
  state : RenderState,
) -> String {
  row.map(cell => render_cell(cell, state)).join(", ")
}

///|
fn render_cell(
  cell : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  let rendered = render_node(cell, state)
  if rendered == "" { "zws" } else { rendered }
}

///|
/// Typst `cases` takes one variadic argument per branch (row); cells within a
/// branch are aligned with `&`.
fn render_cases(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  let items = body
    .map(row => row.map(cell => render_cell(cell, state)).join(" & "))
  "cases(\{items.join(", ")})"
}

///|
fn render_aligned(
  body : Array[Array[@katex_parser.ParseNode]],
  state : RenderState,
) -> String {
  body
    .map(row => row.map(cell => render_cell(cell, state)).join(" & "))
    .join(" \\ ")
}
