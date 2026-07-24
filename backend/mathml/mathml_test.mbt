///|
test "render MathML document and escape TeX annotation" {
  inspect(
    render(
      @katex_parser.parse("x < y"),
      config=RenderConfig::make(annotation="x < y & z"),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>x</mi><mo>&lt;</mo><mi>y</mi></mrow><annotation encoding="application/x-tex">x &lt; y &amp; z</annotation></semantics></math>
    ),
  )
}

///|
test "render tokens scripts fractions and roots" {
  inspect(
    render(@katex_parser.parse("\\alpha_2^n + \\frac{a}{b} + \\sqrt[3]{x}")),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><msubsup><mi>α</mi><mn>2</mn><mi>n</mi></msubsup><mo>+</mo><mfrac><mi>a</mi><mi>b</mi></mfrac><mo>+</mo><mroot><mi>x</mi><mn>3</mn></mroot></mrow></semantics></math>
    ),
  )
}

///|
test "render styles fonts accents and named operators" {
  inspect(
    render(
      @katex_parser.parse("\\displaystyle \\mathbf{x} + \\hat{y} + \\sin z"),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mstyle scriptlevel="0" displaystyle="true"><mi mathvariant="bold">x</mi><mo>+</mo><mover accent="true"><mi>y</mi><mo>^</mo></mover><mo>+</mo><mrow><mi mathvariant="normal">sin</mi><mo>⁡</mo></mrow><mi>z</mi></mstyle></semantics></math>
    ),
  )
}

///|
test "render operator names and display limits" {
  inspect(
    render(
      @katex_parser.parse(
        "\\displaystyle \\sum_{i=0}^n \\operatorname{rank}(A)",
      ),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mstyle scriptlevel="0" displaystyle="true"><munderover><mo>∑</mo><mrow><mi>i</mi><mo>=</mo><mn>0</mn></mrow><mi>n</mi></munderover><mrow><mi mathvariant="normal">rank</mi><mo>⁡</mo></mrow><mo stretchy="false">(</mo><mi>A</mi><mo stretchy="false">)</mo></mstyle></semantics></math>
    ),
  )
}

///|
test "render delimiters and arrays" {
  inspect(
    render(
      @katex_parser.parse(
        "\\left(\\begin{matrix}a & b \\\\ c & d\\end{matrix}\\right)",
      ),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mo fence="true">(</mo><mtable rowspacing="0.16em" columnspacing="1em" columnalign="center center"><mtr><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>a</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>b</mi></mstyle></mtd></mtr><mtr><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>c</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>d</mi></mstyle></mtd></mtr></mtable><mo fence="true">)</mo></mrow></semantics></math>
    ),
  )
}
