///|
fn render_genfrac_block(
  numer : @katex_parser.ParseNode,
  denom : @katex_parser.ParseNode,
) -> String {
  let num = render_node_internal(numer, false)
  let den = render_node_internal(denom, false)
  let w = if num.length() > den.length() { num.length() } else { den.length() }
  let bar_w = w + 2
  let bar = '-'.repeat(bar_w)
  pad_center(num, bar_w) + "\n" + bar + "\n" + pad_center(den, bar_w)
}

///|
fn pad_center(s : String, width : Int) -> String {
  let need = width - s.length()
  if need <= 0 {
    return s
  }
  let left = need / 2
  let right = need - left
  ' '.repeat(left) + s + ' '.repeat(right)
}
