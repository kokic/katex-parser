///|
fn infix_side_group(mode : Mode, body : Array[ParseNode]) -> ParseNode {
  match body {
    [group] if group is OrdGroup(..) => group
    _ => OrdGroup(mode~, loc=None, body~, semisimple=false)
  }
}

///|
fn Parser::handle_infix_nodes(
  self : Parser,
  body : Array[ParseNode],
) -> Array[ParseNode] raise ParseFailure {
  let mut infix_index : Int? = None
  let mut replacement : String? = None
  for index, node in body {
    match node {
      Infix(replace_with~, token~, ..) => {
        guard infix_index is None else {
          let loc = match token {
            Some(value) => value.loc
            None => None
          }
          raise InvalidArgument(
            message="only one infix operator per group",
            loc~,
          )
        }
        infix_index = Some(index)
        replacement = Some(replace_with)
      }
      _ => ()
    }
  }
  match (infix_index, replacement) {
    (Some(index), Some(func_name)) => {
      let numer = infix_side_group(self.mode, body[:index].to_owned())
      let denom = infix_side_group(self.mode, body[index + 1:].to_owned())
      let node = if func_name == "\\\\abovefrac" {
        self.call_function(
          func_name,
          [numer, body[index], denom],
          [],
          None,
          None,
        )
      } else {
        self.call_function(func_name, [numer, denom], [], None, None)
      }
      [node]
    }
    _ => body
  }
}
