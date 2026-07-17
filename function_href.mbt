///|
fn href_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\href"],
    2,
    arg_types=[UrlArg, OriginalArg],
    allowed_in_text=true,
    handler=href_handler,
  )
}

///|
fn url_spec() -> FunctionSpec {
  FunctionSpec::make(
    ["\\url"],
    1,
    arg_types=[UrlArg],
    allowed_in_text=true,
    handler=url_handler,
  )
}

///|
fn href_argument(
  args : Array[ParseNode],
  index : Int,
  func_name : String,
) -> String raise ParseFailure {
  guard require_function_arg(args, index, func_name) is Url(url~, ..) else {
    raise InternalInvariant(message="Expected URL argument for " + func_name)
  }
  url
}

///|
fn href_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let href = href_argument(args, 0, context.func_name)
  guard (context.is_trusted)(
    UrlTrust(command="\\href", url=href, protocol=None),
  ) else {
    (context.unsupported_command)("\\href")
  }
  Href(
    mode=context.mode,
    href~,
    body=ord_argument(require_function_arg(args, 1, context.func_name)),
  )
}

///|
fn url_handler(
  context : FunctionContext,
  args : Array[ParseNode],
  _ : Array[ParseNode?],
) -> ParseNode raise ParseFailure {
  let href = href_argument(args, 0, context.func_name)
  guard (context.is_trusted)(UrlTrust(command="\\url", url=href, protocol=None)) else {
    (context.unsupported_command)("\\url")
  }
  let chars = href
    .to_array()
    .map(char => {
      TextOrd(
        mode=Text,
        loc=None,
        text=if char == '~' {
          "\\textasciitilde"
        } else {
          String::from_array([char])
        },
      )
    })
  Href(
    mode=context.mode,
    href~,
    body=ord_argument(Text(mode=context.mode, font="\\texttt", body=chars)),
  )
}
