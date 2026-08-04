///|
/// Renders a stacked fraction block. When `has_bar_line` is false (e.g.
/// `\atop`/`\atopfrac`) the numerator is stacked directly above the
/// denominator with no fraction bar.
fn frac_block(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  state : RenderState,
  has_bar_line? : Bool = true,
) -> Block {
  // Fraction children are typeset at style+1: text for a display-style
  // fraction, script/scriptscript otherwise. The numerator and denominator
  // share the same style, so they must use the same (tight) spacing too.
  let child_tight = state.style != @katex_parser.StyleLevel::DisplayStyle
  let num_state = { ..state, in_display: false, in_tight: child_tight }
  let den_state = { ..state, in_display: false, in_tight: child_tight }
  let num = Block::from(render_node_internal(numer, num_state))
  let den = Block::from(render_node_internal(denom, den_state))
  let bar_w = num.width().max(den.width()) + 2
  let frac = if has_bar_line {
    let bar = Block::from(
      line_style_frac_bar(state.config.line_style).repeat(bar_w),
    )
    num.center(bar_w).above(bar).above(den.center(bar_w))
  } else {
    num.center(bar_w).above(den.center(bar_w))
  }
  { ..frac, baseline: num.height() }
}

///|
fn render_genfrac_block(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  state : RenderState,
  has_bar_line? : Bool = true,
) -> String {
  frac_block(numer, denom, state, has_bar_line~).render()
}

///|
/// Wrap a block with single-line delimiters aligned at its baseline row, so
/// that a delimiter beside a block fraction sits exactly on the fraction bar.
fn wrap_delims(block : Block, left : String?, right : String?) -> Block {
  let l = left.map_or(Block::empty(), d => Block::from(render_delimiter(d)))
  let r = right.map_or(Block::empty(), d => Block::from(render_delimiter(d)))
  l.beside(block).beside(r)
}

///|
/// Renders a bar-less delimited stack (binomial, `\bracefrac`, `\brackfrac`)
/// as a block whose delimiters span both rows. Used in display mode; inline
/// contexts render as `(n,k)` instead.
fn barless_delimited_block(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  left : String?,
  right : String?,
  state : RenderState,
) -> Block {
  let child_tight = state.style != @katex_parser.StyleLevel::DisplayStyle
  let num_state = { ..state, in_display: false, in_tight: child_tight }
  let den_state = { ..state, in_display: false, in_tight: child_tight }
  let num = Block::from(render_node_internal(numer, num_state))
  let den = Block::from(render_node_internal(denom, den_state))
  let w = num.width().max(den.width())
  let l = left.map_or("", render_delimiter)
  let r = right.map_or("", render_delimiter)
  let lines = [
    "\{l}\{center_text(num.render(), w)}\{r}",
    "\{l}\{center_text(den.render(), w)}\{r}",
  ]
  { lines, width: w + display_width(l) + display_width(r), baseline: 0 }
}
