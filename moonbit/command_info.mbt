///|
/// The builtin table from which a completion command originates.
pub(all) enum CommandKind {
  SymbolCommand
  FunctionCommand
  MacroCommand
  ImplicitCommand
}

///|
/// How a command consumes input. Only RegularCommand can be completed by
/// appending bracketed args alone; use templates for the other forms.
pub(all) enum CommandSyntax {
  RegularCommand
  InfixCommand
  DeclarationCommand
  DelimiterCommand
  EnvironmentCommand
  VerbatimCommand
  DefinitionCommand
  TokenCommand
  GroupCommand
}

///|
/// An explicit argument, in input order. A missing arg_type means the builtin
/// macro's argument type is not declared. Optional arguments use square brackets.
pub struct CommandArgument {
  arg_type : ArgType?
  optional : Bool
}

///|
/// A snapshot of one public builtin command, including its leading backslash.
/// args describes explicit arguments, not an infix operand or an implicit body.
/// modes is absent when a macro's mode restrictions are not statically known.
/// unicode/group describe its registered symbol, when available.
/// templates use named ${field} placeholders, as accepted by CodeMirror's
/// snippetCompletion. Regular commands list the form without optional args first.
/// Templates are editing skeletons, not necessarily valid until fields are filled.
pub struct CommandInfo {
  name : String
  kind : CommandKind
  syntax : CommandSyntax
  args : Array[CommandArgument]
  modes : Array[Mode]?
  unicode : String?
  group : String?
  templates : Array[String]
}

///|
pub impl ToJson for CommandKind with fn to_json(self) {
  let name = match self {
    SymbolCommand => "symbol"
    FunctionCommand => "function"
    MacroCommand => "macro"
    ImplicitCommand => "implicit"
  }
  name.to_json()
}

///|
pub impl ToJson for CommandSyntax with fn to_json(self) {
  let name = match self {
    RegularCommand => "regular"
    InfixCommand => "infix"
    DeclarationCommand => "declaration"
    DelimiterCommand => "delimiter"
    EnvironmentCommand => "environment"
    VerbatimCommand => "verbatim"
    DefinitionCommand => "definition"
    TokenCommand => "token"
    GroupCommand => "group"
  }
  name.to_json()
}

///|
fn command_arg_type_name(kind : ArgType) -> String {
  match kind {
    ColorArg => "color"
    SizeArg => "size"
    UrlArg => "url"
    RawArg => "raw"
    OriginalArg => "original"
    HboxArg => "hbox"
    PrimitiveArg => "primitive"
    MathArg => "math"
    TextArg => "text"
  }
}

///|
pub impl ToJson for CommandArgument with fn to_json(self) {
  {
    "type": self.arg_type.map_or(Json::null(), kind => {
      command_arg_type_name(kind).to_json()
    }),
    "optional": self.optional.to_json(),
  }
}

///|
/// Serializes metadata as ordinary JSON objects and lowercase string tags.
pub impl ToJson for CommandInfo with fn to_json(self) {
  {
    "name": self.name.to_json(),
    "kind": self.kind.to_json(),
    "syntax": self.syntax.to_json(),
    "args": self.args.to_json(),
    "modes": self.modes.map_or(Json::null(), modes => {
      modes
      .map(mode => {
        match mode {
          Math => "math"
          Text => "text"
        }
      })
      .to_json()
    }),
    "unicode": self.unicode.map_or(Json::null(), value => value.to_json()),
    "group": self.group.map_or(Json::null(), value => value.to_json()),
    "templates": self.templates.to_json(),
  }
}

///|
/// Returns fresh, name-sorted completion metadata for the parser's builtins.
/// Includes symbols, functions, static/dynamic macros, implicit commands and
/// supported starred command forms. Internal names and raw Unicode aliases
/// are excluded. No handlers are run and no parser state is changed.
/// This describes default builtins, not settings-dependent or user macros.
pub fn builtin_commands() -> Array[CommandInfo] {
  let commands : Map[String, CommandInfo] = Map([])
  for
    (mode, symbols) in [
      (Math, builtin_symbols.math),
      (Text, builtin_symbols.text),
    ] {
    for name, symbol in symbols {
      guard is_public_builtin_command(name) else { continue }
      let modes = commands
        .get(name)
        .map_or([], info => info.modes.unwrap_or([]))
      modes.push(mode)
      let info = commands
        .get(name)
        .unwrap_or({
          name,
          kind: SymbolCommand,
          syntax: RegularCommand,
          args: [],
          modes: None,
          unicode: if symbol.replacement == "" {
            None
          } else {
            Some(symbol.replacement)
          },
          group: Some(command_symbol_group_name(symbol.group)),
          templates: [name],
        })
      commands[name] = { ..info, modes: Some(modes), }
    }
  }
  // Match parser resolution: macro expansion, then functions, then symbols.
  for name, spec in builtin_function_registry.entries {
    guard is_public_builtin_command(name) else { continue }
    commands[name] = function_command_info(name, spec, commands.get(name))
  }
  for name, _ in builtin_dynamic_macro_definitions {
    guard is_public_builtin_command(name) else { continue }
    commands[name] = macro_command_info(name, [], commands.get(name))
  }
  for name, definition in builtin_static_macro_definitions {
    guard is_public_builtin_command(name) else { continue }
    let count = match definition {
      Text(expansion) => inferred_argument_count(expansion)
      Expansion(expansion) => expansion.num_args
    }
    commands[name] = macro_command_info(
      name,
      Array::makei(count, _ => { arg_type: None, optional: false, }),
      commands.get(name),
    )
  }
  for name in ["\\limits", "\\nolimits", "\\begingroup", "\\endgroup"] {
    let info : CommandInfo = {
      name,
      kind: ImplicitCommand,
      syntax: if name == "\\limits" || name == "\\nolimits" {
        TokenCommand
      } else {
        GroupCommand
      },
      args: [],
      modes: Some(
        if name == "\\limits" || name == "\\nolimits" {
          [Math]
        } else {
          [Math, Text]
        },
      ),
      unicode: None,
      group: None,
      templates: [name],
    }
    commands[name] = complete_command_signature(info)
  }
  let result : Array[CommandInfo] = []
  for _, info in commands {
    result.push(info)
    if info.name == "\\operatorname" ||
      info.name == "\\tag" ||
      info.name == "\\hspace" ||
      info.name == "\\verb" {
      result.push(
        complete_command_signature({ ..info, name: info.name + "*", }),
      )
    }
  }
  result.sort_by((left, right) => left.name.compare(right.name))
  result.map(info => {
    ..info,
    templates: info.templates.map(template => {
      template
      .replace_all(old="#{", new="${")
      .replace_all(old="\\{", new="\\\\{")
      .replace_all(old="\\}", new="\\\\}")
    }),
  })
}

///|
/// Exports the builtin completion catalogue as a JSON array.
pub fn builtin_commands_json() -> Json {
  builtin_commands().to_json()
}

///|
pub extend CommandKind with ToJson::{to_json}

///|
pub extend CommandSyntax with ToJson::{to_json}

///|
pub extend CommandArgument with ToJson::{to_json}

///|
pub extend CommandInfo with ToJson::{to_json}
