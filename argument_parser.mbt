///|
fn Parser::switch_mode(self : Parser, mode : Mode) -> Unit {
  guard self.mode != mode else { () }
  self.mode = mode
  self.gullet.switch_mode(mode)
}

///|
fn Parser::parse_arguments(
  self : Parser,
  func : String,
  func_data : FunctionSpec,
) -> (Array[ParseNode], Array[ParseNode?]) raise ParseFailure {
  let args : Array[ParseNode] = []
  let opt_args : Array[ParseNode?] = []
  let total_args = func_data.num_args + func_data.num_optional_args
  for i in 0..<total_args {
    let optional = i < func_data.num_optional_args
    let arg_type = match func_data.arg_types.get(i) {
      Some(kind) => kind
      None if func_data.primitive => PrimitiveArg
      None if func_data.primitive_after_missing_optional is Some(optional_index) &&
        i == func_data.num_optional_args &&
        opt_args.get(optional_index) is Some(None) => PrimitiveArg
      None => OriginalArg
    }
    match
      self.parse_group_of_type("argument to '" + func + "'", arg_type, optional) {
      None if optional => {
        opt_args.push(None)
        continue
      }
      None =>
        raise InternalInvariant(
          message="Null mandatory function argument after parser validation",
        )
      Some(arg) => {
        if optional {
          opt_args.push(Some(arg))
        } else {
          args.push(arg)
        }
        continue
      }
    }
  } nobreak {
    (args, opt_args)
  }
}

///|
fn Parser::parse_group_of_type(
  self : Parser,
  name : String,
  arg_type : ArgType,
  optional : Bool,
) -> ParseNode? raise ParseFailure {
  match arg_type {
    ColorArg => self.parse_color_group(optional)
    SizeArg => self.parse_size_group(optional)
    UrlArg => self.parse_url_group(optional)
    RawArg =>
      self
      .parse_string_group(optional)
      .map(token => Raw(mode=Text, string=token.text))
    MathArg => self.parse_argument_group(optional, Some(Math))
    TextArg => self.parse_argument_group(optional, Some(Text))
    HboxArg =>
      self
      .parse_argument_group(optional, Some(Text))
      .map(group => {
        Styling(
          mode=group.mode(),
          body=[group],
          style=TextStyle,
          reset_font=true,
        )
      })
    PrimitiveArg => self.parse_primitive_group(name, optional)
    OriginalArg => self.parse_argument_group(optional, None)
  }
}

///|
fn Parser::parse_primitive_group(
  self : Parser,
  name : String,
  optional : Bool,
) -> ParseNode? raise ParseFailure {
  guard !optional else {
    raise InvalidArgument(
      message="A primitive argument cannot be optional",
      loc=None,
    )
  }
  match self.parse_group(name, None) {
    Some(EmitAtom(group)) => Some(group)
    Some(SkipAtom) | None => {
      let token = self.fetch()
      raise InvalidArgument(message="Expected group as " + name, loc=token.loc)
    }
  }
}

///|
fn Parser::parse_argument_group(
  self : Parser,
  optional : Bool,
  mode : Mode?,
) -> ParseNode? raise ParseFailure {
  match self.gullet.scan_argument(optional) {
    None => None
    Some(arg_token) => {
      let outer_mode = self.mode
      match mode {
        Some(argument_mode) => self.switch_mode(argument_mode)
        None => ()
      }
      self.gullet.begin_group()
      let result : Result[ParseNode, ParseFailure] = capture_parse_result(() => {
        let body = self.parse_expression(false, Some("EOF"))
        self.expect("EOF")
        OrdGroup(mode=self.mode, loc=arg_token.loc, body~, semisimple=false)
      })
      let close_result : Result[Unit, ParseFailure] = capture_parse_result(() => {
        self.gullet.end_group()
      })
      self.switch_mode(outer_mode)
      match (close_result, result) {
        (Err(err), _) => raise err
        (_, Err(err)) => raise err
        (Ok(_), Ok(node)) => Some(node)
      }
    }
  }
}
