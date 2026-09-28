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
  count : Int,
  optional : Int,
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
) -> Array[String] {
  let required = StringBuilder()
  let full = StringBuilder()
  required.write_string(name)
  full.write_string(name)
  let mut has_optional = false
  for index, arg in args {
    let field = "#{arg\{index + 1}}"
    if arg.optional {
      has_optional = true
      full.write_string("[\{field}]")
    } else {
      required.write_string("{\{field}}")
      full.write_string("{\{field}}")
    }
  }
  if has_optional {
    [required.to_string(), full.to_string()]
  } else {
    [required.to_string()]
  }
}

///|
fn function_command_info(
  name : String,
  spec : FunctionSpec,
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
  complete_command_signature({
    name,
    kind: FunctionCommand,
    syntax: if spec.infix {
      InfixCommand
    } else {
      RegularCommand
    },
    args,
    modes: Some(modes),
    unicode: symbol.map_or(None, info => info.unicode),
    group: symbol.map_or(None, info => info.group),
    templates: command_templates(name, args),
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
/// Templates use #{field} internally so the JS backend never embeds a literal
/// ${field} in a generated JavaScript template string. Export normalizes it.
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
          name + "{\\#{name}}{#{definition}}",
          name + "{\\#{name}}[#{count}]{#{definition}}",
        ],
      }
    "\\def" | "\\gdef" | "\\edef" | "\\xdef" =>
      {
        ..info,
        syntax: DefinitionCommand,
        args: command_arguments(3, 0, [RawArg, RawArg, RawArg], RawArg),
        templates: [name + "\\#{name}#{parameters}{#{definition}}"],
      }
    "\\let" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(2, 0, [], RawArg),
        templates: [name + "\\#{name}=\\#{command}"],
      }
    "\\futurelet" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(3, 0, [], RawArg),
        templates: [name + "\\#{name}\\#{next}\\#{command}"],
      }
    "\\global" | "\\long" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(1, 0, [], RawArg),
        templates: [name + "\\#{command}"],
      }
    "\\noexpand" | "\\show" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(1, 0, [], RawArg),
        templates: [name + "\\#{command}"],
      }
    "\\expandafter" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(2, 0, [], RawArg),
        templates: [name + "\\#{first}\\#{second}"],
      }
    "\\char" =>
      {
        ..info,
        syntax: TokenCommand,
        args: command_arguments(1, 0, [], RawArg),
        templates: [name + "\"#{hex} ", name + "\u{0060}#{character}"],
      }
    "\\verb" | "\\verb*" =>
      {
        ..info,
        syntax: VerbatimCommand,
        args: command_arguments(1, 0, [], RawArg),
        templates: [name + "|#{text}|"],
      }
    "\\left" =>
      {
        ..info,
        syntax: DelimiterCommand,
        templates: ["\\left(#{body}\\right)"],
      }
    "\\right"
    | "\\middle"
    | "\\big"
    | "\\Big"
    | "\\bigg"
    | "\\Bigg"
    | "\\bigl"
    | "\\Bigl"
    | "\\biggl"
    | "\\Biggl"
    | "\\bigr"
    | "\\Bigr"
    | "\\biggr"
    | "\\Biggr"
    | "\\bigm"
    | "\\Bigm"
    | "\\biggm"
    | "\\Biggm" =>
      { ..info, syntax: DelimiterCommand, templates: [name + " #{delimiter}"], }
    "\\begin" =>
      {
        ..info,
        syntax: EnvironmentCommand,
        templates: environment_command_templates(),
      }
    "\\end" => {
      let templates : Array[String] = []
      for spec in builtin_environments {
        for env in spec.names {
          templates.push("\\end{\{env}}")
        }
      }
      { ..info, syntax: EnvironmentCommand, templates, }
    }
    "\\begingroup" =>
      {
        ..info,
        syntax: GroupCommand,
        templates: [name + " #{body}\\endgroup"],
      }
    "\\bgroup" =>
      { ..info, syntax: GroupCommand, templates: [name + " #{body}\\egroup"], }
    "\\egroup" => { ..info, syntax: GroupCommand, }
    "\\(" => { ..info, syntax: GroupCommand, templates: ["\\(#{body}\\)"], }
    "\\)" | "\\]" => { ..info, syntax: GroupCommand, }
    "\\color" =>
      {
        ..info,
        syntax: DeclarationCommand,
        templates: ["{\\color{#{color}} #{body}}"],
      }
    "\\over" | "\\choose" | "\\atop" | "\\brace" | "\\brack" =>
      { ..info, templates: ["{#{left} " + name + " #{right}}"], }
    "\\above" => { ..info, templates: ["{#{left} \\above{#{size}} #{right}}"], }
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
          templates: ["{" + name + " #{body}}"],
        }
      } else {
        info
      }
    }
  }
}

///|
fn environment_command_templates() -> Array[String] {
  let templates : Array[String] = []
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
      for opening in command_templates("\\begin{\{env}}", args) {
        templates.push(opening + "\n#{body}\n\\end{\{env}}")
      }
    }
  }
  templates.sort()
  templates
}
