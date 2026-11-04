///|
fn html_data_attributes(
  value : String,
) -> Map[String, String] raise ParseFailure {
  let attributes : Map[String, String] = Map([])
  for item in value.split(",") {
    guard item.split_once("=") is Some((key, data_value)) else {
      raise InvalidArgument(
        message="\\htmlData key/value '\{item}' missing equals sign",
        loc=None,
      )
    }
    let key = key.trim(chars=" \t\n\r")
    attributes["data-\{key}"] = data_value.to_owned()
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
      message="Expected raw argument for \{context.func_name}",
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
  let body = ord_argument(require_function_arg(args, 1, context.func_name))
  if (context.is_trusted)(trust_context) {
    Html(mode=context.mode, attributes~, body~)
  } else {
    OrdGroup(mode=context.mode, loc=None, body~, semisimple=false)
  }
}
