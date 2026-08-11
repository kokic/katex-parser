///|
/// Battery of representative equations locking in the Typst backend output.
/// Each case renders `tex` with the parser and compares against the expected
/// Typst source; regenerate after intentional emission changes.
let battery_cases : Array[(String, String, String)] = [
  ("sum_limits", "\\sum_{i=0}^{n} i^2", "∑^n_(i = 0) i^2"),
  ("frac", "\\frac{a+1}{b-2}", "(a + 1) / (b − 2)"),
  ("dfrac", "\\dfrac{x}{y}", "display(x / y)"),
  ("tfrac", "\\tfrac{1}{2}", "inline(1 / 2)"),
  ("binom", "\\binom{n}{k}", "binom(n, k)"),
  ("sqrt", "\\sqrt{x^2+y^2}", "sqrt(x^2 + y^2)"),
  ("root", "\\sqrt[3]{x}", "root(3, x)"),
  ("sup_sub", "x_i^2 + a_b^c", "x^2_i + a^c_b"),
  ("prime", "x' + y'' + z'''", "x^′ + y^′′ + z^′′′"),
  ("left_right", "\\left(\\frac{a}{b}\\right)", "lr(\\( a / b \\))"),
  (
    "left_right_big", "\\left\\{ x \\middle| x \\in \\mathbb{R} \\right\\}", "lr(\\{ x mid(∣) x ∈ bb(R) \\})",
  ),
  ("left_dot", "\\left. \\frac{a}{b} \\right|", "a / b lr(size: #2em, ∣)"),
  (
    "big", "\\big( a \\big) + \\Big[ b \\Big] + \\bigg\\{ c \\bigg\\}", "lr(size: #1.2em, \\() a lr(size: #1.2em, \\)) + lr(size: #1.8em, \\[) b lr(size: #1.8em, \\]) + lr(size: #2.4em, \\{) c lr(size: #2.4em, \\})",
  ),
  (
    "matrix", "\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}", "mat(a, b; c, d, delim: \"(\")",
  ),
  (
    "bmatrix", "\\begin{bmatrix} 1 & 2 \\\\ 3 & 4 \\end{bmatrix}", "mat(1, 2; 3, 4, delim: \"[\")",
  ),
  (
    "vmatrix", "\\begin{vmatrix} a & b \\\\ c & d \\end{vmatrix}", "mat(a, b; c, d, delim: \"|\")",
  ),
  (
    "cases", "f(x) = \\begin{cases} x^2 & x > 0 \\\\ 0 & x = 0 \\\\ -x & x < 0 \\end{cases}",
    "f(x) = cases(x^2 & x > 0, 0 & x = 0, − x & x < 0)",
  ),
  (
    "aligned", "\\begin{aligned} x &= y + z \\\\ &= 2 \\end{aligned}", "display(x) & display(= y + z) \\  & display(= 2)",
  ),
  (
    "array_hlines", "\\begin{array}{c|cc} a & b & c \\\\ \\hline d & e & f \\end{array}",
    "#table(\n  columns: 3,\n  align: center,\n  stroke: none,\n  [$a$], table.vline(), [$b$], [$c$],\n  table.hline(),\n  [$d$], [$e$], [$f$],\n)",
  ),
  (
    "array_dash", "\\begin{array}{c|c} a & b \\\\ \\hdashline c & d \\end{array}",
    "#table(\n  columns: 2,\n  align: center,\n  stroke: none,\n  [$a$], table.vline(), [$b$],\n  table.hline(stroke: (thickness: 0.5pt, dash: (2pt, 1pt))),\n  [$c$], [$d$],\n)",
  ),
  (
    "substack", "\\sum_{\\substack{i=0 \\\\ j=0}}^{n} x", "∑^n_mat(script(i = 0); script(j = 0)) x",
  ),
  ("hat", "\\hat{x} + \\widehat{abc}", "hat(x) + hat(a b c)"),
  (
    "accents", "\\vec{v} + \\dot{a} + \\ddot{b} + \\bar{c} + \\tilde{d} + \\tilde{def}",
    "arrow(v) + dot(a) + dot.double(b) + macron(c) + tilde(d) + tilde(d e f)",
  ),
  (
    "arrow_accents", "\\overrightarrow{AB} + \\overleftarrow{CD} + \\vec{x}", "arrow(A B) + arrow.l(C D) + arrow(x)",
  ),
  (
    "overbrace", "\\overbrace{a+b+c}^{n} + \\underbrace{x+y}_{m}", "attach(overbrace(a + b + c), t: n) + attach(underbrace(x + y), b: m)",
  ),
  (
    "xrightarrow", "\\xrightarrow{f} x \\xrightarrow[below]{above} y", "attach(arrow.r, t: f) x attach(arrow.r, t: a b o v e, b: b e l o w) y",
  ),
  ("xleftrightarrow", "a \\xleftrightarrow{g} b", "a attach(arrow.l.r, t: g) b"),
  (
    "not", "\\not= \\quad \\not\\in \\quad \\not<", "cancel(=) #h(1em) cancel(∈) #h(1em) cancel(<)",
  ),
  (
    "pmod", "x \\equiv y \\pmod{n} \\quad a \\bmod b", "x ≡ y #h(0.444em) (mod #h(0.333em) n) #h(1em) a #h(0.056em) mod #h(0.056em) b",
  ),
  (
    "overset", "\\overset{*}{f} \\quad \\underset{x \\to 0}{\\lim}", "limits(op(f))^∗ #h(1em) limits(op(lim))_(x → 0)",
  ),
  (
    "operatorname", "\\operatorname{argmax}_{x} f(x) \\quad \\operatorname*{res}_{x=0}",
    "op(\"argmax\")_x f(x) #h(1em) op(\"res\")_(x = 0)",
  ),
  (
    "text", "\\text{hello world} \\quad \\text{if } x > 0 \\text{ then}", "text\"hello world\" #h(1em) text\"if \" x > 0 text\" then\"",
  ),
  (
    "textbf", "\\textbf{bold} \\quad \\textit{italic} \\quad \\texttt{mono}", "#strong[$text\"bold\"$] #h(1em) #emph[$text\"italic\"$] #h(1em) text\"mono\"",
  ),
  (
    "fonts", "\\mathbb{R} \\mathbf{v} \\mathcal{L} \\mathfrak{g} \\mathsf{S} \\mathtt{t}",
    "bb(R) bold(v) cal(L) frak(g) sans(S) mono(t)",
  ),
  (
    "color", "\\textcolor{red}{x} + \\color{blue}{y}", "text(fill: #rgb(\"#ff0000\"), x) + text(fill: #rgb(\"#0000ff\"), y)",
  ),
  (
    "boxed", "\\boxed{x^2} \\quad \\fcolorbox{red}{yellow}{x}", "#box(stroke: 0.5pt, $display(x^2)$) #h(1em) #box(stroke: 0.5pt + rgb(\"#ff0000\"), fill: rgb(\"#ffff00\"), $x$)",
  ),
  ("rule", "x \\rule{2em}{0.5pt} y", "x #rect(width: 2em, height: 0.5pt) y"),
  ("raisebox", "x \\raisebox{0.5ex}{y} z", "x #place(dy: 0.25em, $y$) z"),
  (
    "kern", "a \\kern0.5em b \\quad a \\! b", "a #h(0.5em) b #h(1em) a #h(-0.167em) b",
  ),
  (
    "spacing", "a \\; b \\quad a \\: b \\quad a \\, b", "a #h(0.278em) b #h(1em) a #h(0.222em) b #h(1em) a #h(0.167em) b",
  ),
  (
    "dddot", "\\dddot{x} \\quad \\ddddot{y}", "accent(x, dot.triple) #h(1em) accent(y, dot.quad)",
  ),
  ("mathring", "\\mathring{A}", "circle(A)"),
  (
    "genfrac", "\\genfrac{}{}{0pt}{}{a}{b} \\quad \\genfrac{(}{)}{0pt}{}{n}{k}",
    "a / b #h(1em) binom(n, k)",
  ),
  (
    "sizing", "{\\small x} + {\\large y}", "text(size: #0.9em, x) + text(size: #1.2em, y)",
  ),
  ("hspace", "a \\hspace{1em} b", "a #h(1em) b"),
  ("phantom", "a\\phantom{b}c", "a #box(height: 0.5em) c"),
  ("smash", "\\smash{x}", "x"),
  ("notsubset", "\\not\\subset A", "cancel(⊂) A"),
  ("lim_op", "\\lim_{x \\to 0} \\frac{\\sin x}{x}", "lim_(x → 0) (sin x) / x"),
  ("coloneqq", "a \\coloneqq b \\quad c := d", "a op(≔) b #h(1em) c : = d"),
  (
    "verts", "\\Vert x \\Vert \\quad \\lVert x \\rVert", "norm(x) #h(1em) norm(x)",
  ),
  (
    "angles", "\\langle x \\rangle \\quad \\lfloor y \\rfloor \\quad \\lceil z \\rceil",
    "⟨ x ⟩ #h(1em) ⌊ y ⌋ #h(1em) ⌈ z ⌉",
  ),
  (
    "dots", "a + \\cdots + z \\quad x_1, \\ldots, x_n", "a + ⋯ + z #h(1em) x_1 , … , x_n",
  ),
  (
    "arrows", "\\to \\leftarrow \\Rightarrow \\Leftrightarrow \\mapsto", "→ ← ⇒ ⇔ ↦",
  ),
  (
    "operators", "\\sin x \\quad \\log_2 n \\quad \\lim_{n \\to \\infty} \\frac{1}{n}",
    "sin x #h(1em) log_2 n #h(1em) lim_(n → ∞) 1 / n",
  ),
  ("frac_nested", "\\frac{\\frac{a}{b}}{\\frac{c}{d}}", "(a / b) / (c / d)"),
  (
    "overline_underline", "\\overline{xy} + \\underline{ab}", "overline(x y) + underline(a b)",
  ),
  (
    "html_mathml", "\\notin \\quad \\neq \\quad \\le \\quad \\ge", "∉ #h(1em) ≠ #h(1em) ≤ #h(1em) ≥",
  ),
  ("pmb", "\\pmb{\\alpha}", "α"),
  ("mathchoice", "\\sum_{i=1}^{n} i", "∑^n_(i = 1) i"),
  (
    "scriptstyle", "\\scriptstyle x \\quad \\scriptscriptstyle y", "script(x #h(1em) sscript(y))",
  ),
  ("sqrt_nested", "\\sqrt{\\sqrt{x}}", "sqrt(sqrt(x))"),
  (
    "text_complex", "\\text{a very long text with spaces and } x^2", "text\"a very long text with spaces and \" x^2",
  ),
]

///|
test "typst battery renders stable output" {
  for case in battery_cases {
    let name = case.0
    let tex = case.1
    let expected = case.2
    @test.assert_eq(
      @typst.render(@katex_parser.parse(tex)),
      expected,
      msg="\{name}",
    )
  }
}
