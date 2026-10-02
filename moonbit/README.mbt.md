# KaTeX Parser

A port of the KaTeX parser, lexing LaTeX math expressions into a typed AST with macro expansion support.

## 0.6.0: array fidelity and reflection

This release fixes [scoped array stretch](https://github.com/kokic/katex-parser/issues/1),
[reflection boxes](https://github.com/kokic/katex-parser/issues/2),
[optional column gaps](https://github.com/kokic/katex-parser/issues/3), and
[array row/tag normalization](https://github.com/kokic/katex-parser/issues/4).

Arrays now expand the current `\arraystretch` macro before leaving its scope,
using KaTeX's numeric-prefix parsing and positive-value validation. Environments
with an explicit stretch, such as `cases` and `smallmatrix`, retain that value.
Trailing empty rows, AMS automatic numbering, `\nonumber` / `\notag`, manual tags,
and CD's final structural empty row follow KaTeX's parser behavior. Row-gap,
horizontal-line, and tag metadata are retained even when a trailing body row
is removed; consumers must not assume their lengths equal the body length.

The public AST/API changes require consumer updates:

- `ArrayColumn::AlignColumn.pre_gap` and `post_gap` are now `Double?`. `None` means
  the renderer chooses the default gap; `Some(0.0)` means explicitly no gap.
  JSON consumers must preserve this distinction too.
- `ArrayEnvironmentOptions.array_stretch` is now `Double?`: `None` reads the current
  macro (default `1.0`), while `Some(value)` specifies the environment's stretch.
  The resolved `ParseNode::Array.array_stretch` remains a `Double`.
- `ArrayEnvironmentOptions` adds `empty_single_row`. Set it to `true` for AMS-style
  environments that retain a single empty row, or `false` for ordinary arrays.
- `ParseNode` adds `ReflectBox(mode~, body~)`. Exhaustive AST consumers must handle
  it. `\reflectbox` parses its body as a text box and is also allowed in text;
  `\mathreflectbox` takes a math argument and is only allowed in math mode.
  Both commands are included in the builtin completion catalogue.

The Unicode backend accepts `ReflectBox` and renders its body without mirroring:
plain text cannot mirror arbitrary glyphs. It also omits CD's structural empty
row when drawing text diagrams.

## Builtin command completions

`builtin_commands()` returns a fresh `Array[CommandInfo]`, sorted by command name.
`builtin_commands_json()` exports the same catalogue as a JSON array. Import
`kokic/katex-parser` as `@katex` in a consumer package:

```moonbit nocheck
///|
let commands = @katex.builtin_commands()

///|
let json = @katex.builtin_commands_json().stringify()
```

Write `json` to a file in your build process, or return it from a JavaScript
binding. The catalogue includes public symbols, functions, builtin macros,
implicit commands and supported starred forms. It excludes internal helpers
and bare Unicode aliases. Exporting never executes a macro or a function handler.

Each entry has these fields:

| Field | Meaning |
| --- | --- |
| `name` | Command spelling, including the leading backslash and any star. |
| `kind` | `SymbolCommand`, `FunctionCommand`, `MacroCommand`, or `ImplicitCommand`. |
| `syntax` | A `CommandSyntax` constructor name, such as `RegularCommand`, `InfixCommand` or `DelimiterCommand`. |
| `args` | Explicit arguments in input order, each with `optional` and, when known, `arg_type`. |
| `modes` | Known allowed modes (`Math`/`Text`); omitted for macros whose restrictions are not declared. |
| `unicode`, `group` | Registered symbol replacement/category; omitted when unavailable. Math metadata is preferred when a symbol has both modes. |
| `templates` | Insertion templates with CodeMirror-compatible `${field}` placeholders. |

The metadata types use `derive(ToJson)` directly. JSON keys match the MoonBit
fields and enum values retain their constructor names. Optional struct fields
are omitted for `None`; `Some(value)` serializes as `value`.

Argument types are `ColorArg`, `SizeArg`, `UrlArg`, `RawArg`, `OriginalArg`,
`HboxArg`, `PrimitiveArg`, `MathArg` and `TextArg`. A macro without a declared
type omits `arg_type`. `OriginalArg` preserves the current parsing mode.
For functions with optional arguments, the optional positions precede the
required ones; special syntax can interleave them.

Only `RegularCommand` commands can be completed by simply appending bracketed
arguments. Other commands may consume tokens, delimiters, infix operands or
the rest of a group. Their templates describe usable editing forms. For
example, `\color` has one explicit color argument but its template also
provides a scoped body. `\begin` templates include matching `\end` commands
and the environment's arguments, including alignment for starred matrices.

Example JSON entry:

```json
{
  "name": "\\sqrt",
  "kind": "FunctionCommand",
  "syntax": "RegularCommand",
  "args": [
    { "arg_type": "OriginalArg", "optional": true },
    { "arg_type": "OriginalArg", "optional": false }
  ],
  "modes": ["Math"],
  "templates": ["\\sqrt{${arg2}}", "\\sqrt[${arg1}]{${arg2}}"]
}
```

For regular commands, the first template omits optional arguments and a
second includes them. Field names are placeholders to replace, not guaranteed
valid default values: a size argument needs a measurement such as `1pt`.
Templates already escape literal TeX `\{` and `\}` for CodeMirror; do not
escape them a second time.

### CodeMirror 6

Generate the options once from the JSON catalogue:

```js
import { snippetCompletion } from "@codemirror/autocomplete";

const options = commands.flatMap(command =>
  command.templates.map(template => snippetCompletion(template, {
    label: command.name,
    displayLabel: template
      .replace(/\$\{[^}]*\}/g, "")
      .replace(/\\([{}])/g, "$1")
      .split("\n")[0],
    type: "keyword",
    detail: command.unicode ?? command.syntax,
  }))
);

function supplyKaTeXCompletions(context) {
  const token = context.matchBefore(/\\(?:[A-Za-z]*\*?|[^A-Za-z\s])/);
  if (!token) return null;
  return { from: token.from, options };
}
```

Pass this source to `autocompletion({ override: [supplyKaTeXCompletions] })`.
Parameter fields support Tab navigation. For another editor, adapt `args`
and `syntax`, or translate the template placeholder and escaping convention.

The catalogue describes default builtins. User-defined macros, extension
specs, settings such as `color_is_text_color`, and context checks such as
display mode, trusted commands, or being inside an array remain the
consumer's responsibility. It is a completion vocabulary, not a promise
that every command parses at every cursor position.
