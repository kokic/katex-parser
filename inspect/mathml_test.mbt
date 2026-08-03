///|
test "render MathML document and escape TeX annotation" {
  inspect(
    @mathml.render(
      @katex_parser.parse("x < y"),
      config=@mathml.RenderConfig::make(annotation="x < y & z"),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>x</mi><mo>&lt;</mo><mi>y</mi></mrow><annotation encoding="application/x-tex">x &lt; y &amp; z</annotation></semantics></math>
    ),
  )
}

///|
test "render display mode independently from math style" {
  inspect(
    @mathml.render(@katex_parser.parse("\\displaystyle x")),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mstyle scriptlevel="0" displaystyle="true"><mi>x</mi></mstyle></semantics></math>
    ),
  )
  inspect(
    @mathml.render(
      @katex_parser.parse("x"),
      config=@mathml.RenderConfig::make(display_mode=true),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mi>x</mi></semantics></math>
    ),
  )
}

///|
test "render tokens scripts fractions and roots" {
  inspect(
    @mathml.render(
      @katex_parser.parse("\\alpha_2^n + \\frac{a}{b} + \\sqrt[3]{x}"),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><msubsup><mi>α</mi><mn>2</mn><mi>n</mi></msubsup><mo>+</mo><mfrac><mi>a</mi><mi>b</mi></mfrac><mo>+</mo><mroot><mi>x</mi><mn>3</mn></mroot></mrow></semantics></math>
    ),
  )
}

///|
test "render styles fonts accents and named operators" {
  inspect(
    @mathml.render(
      @katex_parser.parse("\\displaystyle \\mathbf{x} + \\hat{y} + \\sin z"),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mstyle scriptlevel="0" displaystyle="true"><mi mathvariant="bold">x</mi><mo>+</mo><mover accent="true"><mi>y</mi><mo>^</mo></mover><mo>+</mo><mrow><mi mathvariant="normal">sin</mi><mo>⁡</mo></mrow><mi>z</mi></mstyle></semantics></math>
    ),
  )
}

///|
test "render operator names and display limits" {
  inspect(
    @mathml.render(
      @katex_parser.parse(
        "\\displaystyle \\sum_{i=0}^n \\operatorname{rank}(A)",
      ),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mstyle scriptlevel="0" displaystyle="true"><munderover><mo>∑</mo><mrow><mi>i</mi><mo>=</mo><mn>0</mn></mrow><mi>n</mi></munderover><mrow><mi mathvariant="normal">rank</mi><mo>⁡</mo></mrow><mo stretchy="false">(</mo><mi>A</mi><mo stretchy="false">)</mo></mstyle></semantics></math>
    ),
  )
}

///|
test "render delimiters and arrays" {
  inspect(
    @mathml.render(
      @katex_parser.parse(
        "\\left(\\begin{matrix}a & b \\\\ c & d\\end{matrix}\\right)",
      ),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mo fence="true">(</mo><mtable rowspacing="0.16em" columnspacing="1em" columnalign="center center"><mtr><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>a</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>b</mi></mstyle></mtd></mtr><mtr><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>c</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="false"><mi>d</mi></mstyle></mtd></mtr></mtable><mo fence="true">)</mo></mrow></semantics></math>
    ),
  )
}

///|
test "render aligned environment" {
  inspect(
    @mathml.render(
      @katex_parser.parse("\\begin{aligned}a&=b\\\\c&=d\\end{aligned}"),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mtable rowspacing="0.25em" columnspacing="0em" columnalign="right left"><mtr><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>a</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>b</mi></mrow></mstyle></mtd></mtr><mtr><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>c</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>d</mi></mrow></mstyle></mtd></mtr></mtable></semantics></math>
    ),
  )
  inspect(
    @mathml.render(
      @katex_parser.parse(
        "\\begin{aligned}a&=b&c&=d\\\\e&=f&g&=h\\end{aligned}",
      ),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mtable rowspacing="0.25em" columnspacing="0em 1em 0em" columnalign="right left right left"><mtr><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>a</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>b</mi></mrow></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>c</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>d</mi></mrow></mstyle></mtd></mtr><mtr><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>e</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>f</mi></mrow></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>g</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>h</mi></mrow></mstyle></mtd></mtr></mtable></semantics></math>
    ),
  )
}

///|
test "render align environment in display mode" {
  let settings = @katex_parser.Settings::make(display_mode=true)
  inspect(
    @mathml.render(
      @katex_parser.parse("\\begin{align}a&=b\\\\c&=d\\end{align}", settings~),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mstyle scriptlevel="0" displaystyle="true"><mtable rowspacing="0.25em" columnspacing="0em" columnalign="right left"><mtr><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>a</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>b</mi></mrow></mstyle></mtd></mtr><mtr><mtd><mstyle scriptlevel="0" displaystyle="true"><mi>c</mi></mstyle></mtd><mtd><mstyle scriptlevel="0" displaystyle="true"><mrow><mrow></mrow><mo>=</mo><mi>d</mi></mrow></mstyle></mtd></mtr></mtable></mstyle></semantics></math>
    ),
  )
}

///|
test "render smallmatrix with reduced row spacing" {
  inspect(
    @mathml.render(
      @katex_parser.parse("\\begin{smallmatrix}a&b\\\\c&d\\end{smallmatrix}"),
    ),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mtable rowspacing="0.1em" columnspacing="0.2778em" columnalign="center center"><mtr><mtd><mstyle scriptlevel="1" displaystyle="false"><mi>a</mi></mstyle></mtd><mtd><mstyle scriptlevel="1" displaystyle="false"><mi>b</mi></mstyle></mtd></mtr><mtr><mtd><mstyle scriptlevel="1" displaystyle="false"><mi>c</mi></mstyle></mtd><mtd><mstyle scriptlevel="1" displaystyle="false"><mi>d</mi></mstyle></mtd></mtr></mtable></semantics></math>
    ),
  )
}

///|
test "overlay \\not onto the following symbol" {
  inspect(
    @mathml.render(@katex_parser.parse("\\not=")),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mo>≠</mo></semantics></math>
    ),
  )
  inspect(
    @mathml.render(@katex_parser.parse("\\not<")),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mo>&lt;̸</mo></semantics></math>
    ),
  )
  inspect(
    @mathml.render(@katex_parser.parse("a\\not=b")),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mrow><mi>a</mi><mo>≠</mo><mi>b</mi></mrow></semantics></math>
    ),
  )
  inspect(
    @mathml.render(@katex_parser.parse("\\not x")),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mi>x̸</mi></semantics></math>
    ),
  )
}

///|
test "omit math shell for empty content" {
  inspect(@mathml.render(@katex_parser.parse("\\def\\foo{x}")), content="")
  inspect(
    @mathml.render(@katex_parser.parse("\\def\\foo{x}\\gdef\\bar{y}")),
    content="",
  )
  inspect(
    @mathml.render(@katex_parser.parse("\\def\\foo{x}\\foo")),
    content=(
      #|<math xmlns="http://www.w3.org/1998/Math/MathML"><semantics><mi>x</mi></semantics></math>
    ),
  )
}
