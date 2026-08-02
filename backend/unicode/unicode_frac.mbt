///|
fn frac_block(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  state : RenderState,
) -> Block {
  let num_state = { ..state, in_display: false }
  let den_state = { ..state, in_display: false, in_tight: true }
  let num = Block::from(render_node_internal(numer, num_state))
  let den = Block::from(render_node_internal(denom, den_state))
  let bar_w = num.width().max(den.width()) + 2
  let bar = Block::from(line_style_frac_bar(state.config.line_style).repeat(bar_w))
  let frac = num.center(bar_w).above(bar).above(den.center(bar_w))
  { ..frac, baseline: num.height() }
}

///|
fn render_genfrac_block(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  frac_block(numer, denom, state).render()
}

///|
/// Wrap a block with single-line delimiters aligned at its baseline row, so
/// that a delimiter beside a block fraction sits exactly on the fraction bar.
fn wrap_delims(block : Block, left : String?, right : String?) -> Block {
  let l = left.map_or(Block::empty(), d => Block::from(render_delimiter(d)))
  let r = right.map_or(Block::empty(), d => Block::from(render_delimiter(d)))
  l.beside(block).beside(r)
}
