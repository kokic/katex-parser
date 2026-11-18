///|
fn is_public_builtin_command(name : String) -> Bool {
  name.has_prefix("\\") &&
  name.length() > 1 &&
  !name.contains("@") &&
  (!name.has_prefix("\\\\") || name == "\\\\") &&
  name != "\\DOTSI" &&
  name != "\\DOTSB" &&
  name != "\\DOTSX"
}

///|
fn command_symbol_group_name(group : SymbolGroup) -> String {
  match group {
    AccentTokenGroup => "accent-token"
    BinaryGroup => "binary"
    CloseGroup => "close"
    InnerGroup => "inner"
    MathOrdGroup => "mathord"
    OperatorTokenGroup => "operator-token"
    OpenGroup => "open"
    PunctuationGroup => "punctuation"
    RelationGroup => "relation"
    SpacingGroup => "spacing"
    TextOrdGroup => "textord"
  }
}

///|
fn command_arguments(
  count : Int32,
  optional : Int32,
  types : Array[ArgType],
  fallback : ArgType,
) -> Array[CommandArgument] {
  Array::makei(count + optional, index => {
    arg_type: Some(types.get(index).unwrap_or(fallback)),
    optional: index < optional,
  })
}

///|
fn command_templates(
  name : String,
  args : Array[CommandArgument],
) -> Array[CommandTemplate] {
  fn form(include_optional : Bool) -> CommandTemplate {
    let parts : CommandTemplate = [Literal(name)]
    for index, arg in args {
      guard !arg.optional || include_optional else { continue }
      let (open, close) = if arg.optional { ("[", "]") } else { ("{", "}") }
      parts.append([Literal(open), Field("arg\{index + 1}"), Literal(close)])
    }
    parts
  }
  if args.any(arg => arg.optional) {
    [form(false), form(true)]
  } else {
    [form(false)]
  }
}

///|
fn function_command_info(
  name : String,
  spec : FunctionSpec,
  form : FunctionCompletionForm,
  symbol : CommandInfo?,
) -> CommandInfo {
  let args = command_arguments(
    spec.num_args,
    spec.num_optional_args,
    spec.arg_types,
    if spec.primitive {
      PrimitiveArg
    } else {
      OriginalArg
    },
  )
  let modes : Array[Mode] = []
  if spec.allowed_in_math {
    modes.push(Math)
  }
  if spec.allowed_in_text {
    modes.push(Text)
  }
  let (syntax, templates) : (CommandSyntax, Array[CommandTemplate]) = match
    form {
    DefaultForm =>
      (
        if spec.infix {
          InfixCommand
        } else {
          RegularCommand
        },
        command_templates(name, args),
      )
    DelimiterTokenForm =>
      (DelimiterCommand, [[Literal(name + " "), Field("delimiter")]])
    DelimiterPairForm =>
      (
        DelimiterCommand,
        [[Literal(name + "("), Field("body"), Literal("\\right)")]],
      )
  }
  complete_command_signature({
    name,
    kind: FunctionCommand,
    syntax,
    args,
    modes: Some(modes),
    unicode: symbol.map_or(None, info => info.unicode),
    group: symbol.map_or(None, info => info.group),
    templates,
  })
}

///|
fn macro_command_info(
  name : String,
  args : Array[CommandArgument],
  symbol : CommandInfo?,
) -> CommandInfo {
  complete_command_signature({
    name,
    kind: MacroCommand,
    syntax: RegularCommand,
    args,
    modes: None,
    unicode: symbol.map_or(None, info => info.unicode),
    group: symbol.map_or(None, info => info.group),
    templates: command_templates(name, args),
  })
}

///|
/// Correct public signatures whose input is consumed by handlers or by
/// expanded aliases rather than by the function/macro's own argument list.
fn complete_command_signature(info : CommandInfo) -> CommandInfo {
  let name = info.name
  match name {
    "\\operatorname" | "\\operatorname*" | "\\Braket" | "\\Set" | "\\set" => {
      let args = command_arguments(1, 0, [], OriginalArg)
      { ..info, args, templates: command_templates(name, args), }
    }
    "\\tag" | "\\tag*" => {
      let args = command_arguments(1, 0, [TextArg], TextArg)
      { ..info, args, templates: command_templates(name, args), }
    }
    "\\hspace" | "\\hspace*" => {
      let args = command_arguments(1, 0, [SizeArg], SizeArg)
      { ..info, args, templates: command_templates(name, args), }
    }
    "\\TextOrMath" => {
      let args = command_arguments(2, 0, [TextArg, MathArg], OriginalArg)
      { ..info, args, templates: command_templates(name, args), }
    }
    "\\message" | "\\errmessage" => {
      let args = command_arguments(1, 0, [RawArg], RawArg)
      { ..info, args, templates: command_templates(name, args), }
    }
    "\\\\" => {
      let args = command_arguments(0, 1, [SizeArg], SizeArg)
      { ..info, args, templates: command_templates(name, args), }
    }
    "\\newcommand" | "\\renewcommand" | "\\providecommand" =>
      {
        ..info,
        syntax: DefinitionCommand,
        args: [
          { arg_type: Some(RawArg), optional: false, },
          { arg_type: Some(RawArg), optional: true, },
          { arg_type: Some(RawArg), optional: false, },
        ],
        templates: [
          [
            Literal(name + "{\\"),
            Field("name"),
            Literal("}{"),
            Field("definition"),
            Literal("}"),
          ],
          [
            Literal(name + "{\\"),
            Field("name"),
            Literal("}["),
            Field("count"),
            Literal("]{"),
            Field("definition"),
            Literal("}"),
          ],
        ],
      }
    "\\def" | "\\gdef" | "\\edef" | "\\xdef" =>
      {
        ..info,
        syntax: DefinitionCommand,
        args: command_arguments(3, 0, [RawArg, RawArg, RawArg], RawArg),
        templates: [
          [
            Literal(name + "\\"),
            Field("name"),
            Field("parameters"),
            Literal("{"),
            Field("definition"),
            Literal("}"),
          ],
        ],
      }
    "\\let" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(2, 0, [], RawArg),
        templates: [
          [
            Literal(name + "\\"),
            Field("name"),
            Literal("=\\"),
            Field("command"),
          ],
        ],
      }
    "\\futurelet" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(3, 0, [], RawArg),
        templates: [
          [
            Literal(name + "\\"),
            Field("name"),
            Literal("\\"),
            Field("next"),
            Literal("\\"),
            Field("command"),
          ],
        ],
      }
    "\\global" | "\\long" | "\\noexpand" | "\\show" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(1, 0, [], RawArg),
        templates: [[Literal(name + "\\"), Field("command")]],
      }
    "\\expandafter" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(2, 0, [], RawArg),
        templates: [
          [Literal(name + "\\"), Field("first"), Literal("\\"), Field("second")],
        ],
      }
    "\\char" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(1, 0, [], RawArg),
        templates: [
          [Literal(name + "\""), Field("hex"), Literal(" ")],
          [Literal(name + "`"), Field("character")],
        ],
      }
    "\\verb" | "\\verb*" =>
      {
        ..info,
        syntax: VerbatimCommand,
        args: command_arguments(1, 0, [], RawArg),
        templates: [[Literal(name + "|"), Field("text"), Literal("|")]],
      }
    "\\begin" =>
      {
        ..info,
        syntax: EnvironmentCommand,
        templates: environment_command_templates(),
      }
    "\\end" => {
      let templates : Array[CommandTemplate] = []
      for spec in builtin_environments {
        for env in spec.names {
          templates.push([Literal("\\end{\{env}}")])
        }
      }
      { ..info, syntax: EnvironmentCommand, templates, }
    }
    "\\begingroup" =>
      {
        ..info,
        syntax: GroupCommand,
        templates: [[Literal(name + " "), Field("body"), Literal("\\endgroup")]],
      }
    "\\bgroup" =>
      {
        ..info,
        syntax: GroupCommand,
        templates: [[Literal(name + " "), Field("body"), Literal("\\egroup")]],
      }
    "\\egroup" => { ..info, syntax: GroupCommand, }
    "\\(" =>
      {
        ..info,
        syntax: GroupCommand,
        templates: [[Literal("\\("), Field("body"), Literal("\\)")]],
      }
    "\\)" | "\\]" => { ..info, syntax: GroupCommand, }
    "\\color" =>
      {
        ..info,
        syntax: DeclarationCommand,
        templates: [
          [
            Literal("{\\color{"),
            Field("color"),
            Literal("} "),
            Field("body"),
            Literal("}"),
          ],
        ],
      }
    "\\over" | "\\choose" | "\\atop" | "\\brace" | "\\brack" =>
      {
        ..info,
        templates: [
          [
            Literal("{"),
            Field("left"),
            Literal(" " + name + " "),
            Field("right"),
            Literal("}"),
          ],
        ],
      }
    "\\above" =>
      {
        ..info,
        templates: [
          [
            Literal("{"),
            Field("left"),
            Literal(" \\above{"),
            Field("size"),
            Literal("} "),
            Field("right"),
            Literal("}"),
          ],
        ],
      }
    _ => {
      let declaration = sizing_commands.contains(name) ||
        old_font_commands.any(command => command.name == name) ||
        name == "\\displaystyle" ||
        name == "\\textstyle" ||
        name == "\\scriptstyle" ||
        name == "\\scriptscriptstyle"
      if declaration {
        {
          ..info,
          syntax: DeclarationCommand,
          templates: [[Literal("{" + name + " "), Field("body"), Literal("}")]],
        }
      } else {
        info
      }
    }
  }
}

///|
fn environment_command_templates() -> Array[CommandTemplate] {
  let templates : Array[CommandTemplate] = []
  for spec in builtin_environments {
    for env in spec.names {
      let args = if env.has_suffix("matrix*") {
        command_arguments(0, 1, [RawArg], RawArg)
      } else {
        command_arguments(
          spec.num_args,
          spec.num_optional_args,
          spec.arg_types,
          OriginalArg,
        )
      }
      let begin = "\\begin{\{env}}"
      for form in command_templates(begin, args) {
        form.append([Literal("\n"), Field("body"), Literal("\n\\end{\{env}}")])
        templates.push(form)
      }
    }
  }
  templates
}
