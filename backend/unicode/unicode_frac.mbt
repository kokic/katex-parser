///|
fn render_genfrac_block(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
  state : RenderState,
) -> String {
  let num_state = { ..state, in_display: false }
  let den_state = { ..state, in_display: false, in_tight: true }
  let num = Block::from(render_node_internal(numer, num_state))
  let den = Block::from(render_node_internal(denom, den_state))
  let bar_w = num.width().max(den.width()) + 2
  let bar = Block::from("-".repeat(bar_w))
  let frac = num.center(bar_w).above(bar).above(den.center(bar_w))
  { ..frac, baseline: num.height() }.render()
}
