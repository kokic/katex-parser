///|
fn includegraphics_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\includegraphics"],
    1,
    num_optional_args=1,
    arg_types=[RawArg, UrlArg],
    handler=includegraphics_handler,
  )
}

///|
fn graphics_number(text : String) -> String? {
  let mut index = 0
  let mut sign = ""
  if index < text.length() && (text[index] == '+' || text[index] == '-') {
    sign = text.unsafe_substring(start=0, end=1)
    index = 1
    while index < text.length() && text[index] == ' ' {
      index = index + 1
    }
  }
  let start = index
  while index < text.length() && text[index] >= '0' && text[index] <= '9' {
    index = index + 1
  }
  let before = index - start
  let mut after = 0
  if index < text.length() && text[index] == '.' {
    index = index + 1
    let fraction_start = index
    while index < text.length() && text[index] >= '0' && text[index] <= '9' {
      index = index + 1
    }
    after = index - fraction_start
  }
  if index != text.length() || (before == 0 && after == 0) {
    None
  } else {
    Some(sign + text.unsafe_substring(start~, end=text.length()))
  }
}

///|
fn graphics_size(text : String) -> Measurement raise ParseFailure {
  let text = trim_ascii_spaces(text)
  match graphics_number(text) {
    Some(number_text) =>
      return { number: parse_decimal(number_text), unit: "bp" }
    None => ()
  }
  match parse_size_measurement(text) {
    Some(size) if valid_size_unit(size.unit) => size
    Some(size) =>
      raise InvalidArgument(
        message="Invalid unit: '" + size.unit + "' in \\includegraphics.",
        loc=None,
      )
    None =>
      raise InvalidArgument(
        message="Invalid size: '" + text + "' in \\includegraphics",
        loc=None,
      )
  }
}

///|
fn graphics_option_items(value : String) -> Array[String] {
  let items : Array[String] = []
  let mut start = 0
  for index = 0; index <= value.length(); index = index + 1 {
    if index == value.length() || value[index] == ',' {
      items.push(value.unsafe_substring(start~, end=index))
      start = index + 1
    }
  }
  items
}

///|
fn graphics_option_pair(item : String) -> (String, String)? {
  let mut equals = -1
  let mut count = 0
  for index = 0; index < item.length(); index = index + 1 {
    if item[index] == '=' {
      equals = index
      count = count + 1
    }
  }
  if count != 1 {
    None
  } else {
    Some(
      (
        trim_ascii_spaces(item.unsafe_substring(start=0, end=equals)),
        trim_ascii_spaces(
          item.unsafe_substring(start=equals + 1, end=item.length()),
        ),
      ),
    )
  }
}

///|
fn graphics_default_alt(src : String) -> String {
  let mut name_start = 0
  let mut extension = -1
  for index = 0; index < src.length(); index = index + 1 {
    if src[index] == '/' || src[index] == '\\' {
      name_start = index + 1
      extension = -1
    } else if src[index] == '.' {
      extension = index
    }
  }
  if extension < name_start {
    ""
  } else {
    src.unsafe_substring(start=name_start, end=extension)
  }
}

///|
fn includegraphics_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  opt_args : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let mut width = { number: 0.0, unit: "em" }
  let mut height = { number: 0.9, unit: "em" }
  let mut totalheight = { number: 0.0, unit: "em" }
  let mut alt = ""
  match opt_args.get(0) {
    Some(Some(Raw(string=value, ..))) =>
      for item in graphics_option_items(value) {
        match graphics_option_pair(item) {
          None => ()
          Some((key, value)) =>
            match key {
              "alt" => alt = value
              "width" => width = graphics_size(value)
              "height" => height = graphics_size(value)
              "totalheight" => totalheight = graphics_size(value)
              _ =>
                raise InvalidArgument(
                  message="Invalid key: '" + key + "' in \\includegraphics.",
                  loc=None,
                )
            }
        }
      }
    Some(Some(_)) =>
      raise InternalInvariant(message="Expected raw graphics options")
    Some(None) | None => ()
  }
  guard require_function_arg(args, 0, context.func_name) is Url(url=src, ..) else {
    raise InternalInvariant(
      message="Expected URL argument for \\includegraphics",
    )
  }
  if alt == "" {
    alt = graphics_default_alt(src)
  }
  if !(context.is_trusted)(
      UrlTrust(command="\\includegraphics", url=src, protocol=None),
    ) {
    return (context.unsupported_command)(context.func_name)
  }
  IncludeGraphics(mode=context.mode, alt~, width~, height~, totalheight~, src~)
}
