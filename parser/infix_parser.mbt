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
  let mut infix : (Int, String)? = None
  for index, node in body {
    match node {
      Infix(replace_with~, loc~, ..) => {
        guard infix is None else {
          raise InvalidArgument(
            message="only one infix operator per group",
            loc~,
          )
        }
        infix = Some((index, replace_with))
      }
      _ => ()
    }
  }
  match infix {
    Some((index, func_name)) => {
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
