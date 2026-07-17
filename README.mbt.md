# KaTeX Parser

`kokic/katex-parser` parses KaTeX-compatible LaTeX math into a typed MoonBit AST.

## Parse

```mbt nocheck
import {
  "kokic/katex-parser" @katex_parser,
}

fn parse_formula(source : String) {
  @katex_parser.parse(source)
}
```

`parse` raises `ParseFailure`. Source locations are UTF-16 offsets in the input
string and are attached to diagnostics when available.

## Options And Macros

```mbt nocheck
import {
  "kokic/katex-parser" @katex_parser,
}

fn parse_with_macros(source : String) {
  let macros = Map([
    ("\\vect", "\\mathbf{#1}"),
  ])
  let settings = @katex_parser.Settings::make(
    display_mode=true,
    macros~,
  )
  @katex_parser.parse(source, settings=settings)
}
```

The macro map contains TeX expansion text. It supports positional parameters
such as `#1` and is copied into each parse, so parsing does not mutate caller
configuration.

`Settings::make` configures strictness, trust policy, expansion limits, display
mode, diagnostics, and error rendering. `ParseNode` is the public AST. Token
and macro-expansion machinery are intentionally private implementation details.
