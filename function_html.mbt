///|
fn trim_ascii_spaces(text : String) -> String {
  let mut start = 0
  let mut end = text.length()
  while start < end &&
        (
          text[start] == ' ' ||
          text[start] == '\t' ||
          text[start] == '\n' ||
          text[start] == '\r'
        ) {
    start = start + 1
  }
  while end > start &&
        (
          text[end - 1] == ' ' ||
          text[end - 1] == '\t' ||
          text[end - 1] == '\n' ||
          text[end - 1] == '\r'
        ) {
    end = end - 1
  }
  text.unsafe_substring(start~, end~)
}

///|
fn html_data_attributes(
  value : String,
) -> Map[String, String] raise ParseFailure {
  let attributes : Map[String, String] = Map([])
  let mut start = 0
  for index = 0; index <= value.length(); index = index + 1 {
    if index == value.length() || value[index] == ',' {
      let item = value.unsafe_substring(start~, end=index)
      let mut equals = -1
      for offset = 0; offset < item.length(); offset = offset + 1 {
        if item[offset] == '=' && equals < 0 {
          equals = offset
        }
      }
      guard equals >= 0 else {
        raise InvalidArgument(
          message="\\htmlData key/value '" + item + "' missing equals sign",
          loc=None,
        )
      }
      let key = trim_ascii_spaces(item.unsafe_substring(start=0, end=equals))
      let data_value = item.unsafe_substring(
        start=equals + 1,
        end=item.length(),
      )
      attributes["data-" + key] = data_value
      start = index + 1
    }
  }
  attributes
}

///|
fn html_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\htmlClass", "\\htmlId", "\\htmlStyle", "\\htmlData"],
    2,
    arg_types=[RawArg, OriginalArg],
    allowed_in_text=true,
    handler=html_handler,
  )
}

///|
fn html_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  guard require_function_arg(args, 0, context.func_name)
    is Raw(string=value, ..) else {
    raise InternalInvariant(
      message="Expected raw argument for " + context.func_name,
    )
  }
  (context.report_nonstrict)(
    "htmlExtension", "HTML extension is disabled on strict mode",
  )
  let attributes : Map[String, String] = Map([])
  let trust_context = match context.func_name {
    "\\htmlClass" => {
      attributes["class"] = value
      HtmlClass(class=value)
    }
    "\\htmlId" => {
      attributes["id"] = value
      HtmlId(id=value)
    }
    "\\htmlStyle" => {
      attributes["style"] = value
      HtmlStyle(style=value)
    }
    "\\htmlData" => {
      let parsed = html_data_attributes(value)
      for key, item in parsed {
        attributes[key] = item
      }
      HtmlData(attributes~)
    }
    _ => raise InternalInvariant(message="Unrecognized html command")
  }
  if !(context.is_trusted)(trust_context) {
    return (context.unsupported_command)(context.func_name)
  }
  Html(
    mode=context.mode,
    attributes~,
    body=ord_argument(require_function_arg(args, 1, context.func_name)),
  )
}
