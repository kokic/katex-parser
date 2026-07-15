///|
priv struct Namespace[V] {
  builtins : Map[String, V]
  current : Map[String, V]
  undo_stack : Array[Map[String, V?]]
}

///|
fn[V] Namespace::make(
  builtins : Map[String, V],
  initial : Map[String, V],
) -> Namespace[V] {
  { builtins, current: initial, undo_stack: [] }
}

///|
fn[V] Namespace::begin_group(self : Namespace[V]) -> Unit {
  self.undo_stack.push(Map([]))
}

///|
fn[V] Namespace::restore_group(
  self : Namespace[V],
  changes : Map[String, V?],
) -> Unit {
  for key, old_value in changes {
    match old_value {
      Some(value) => self.current[key] = value
      None => self.current.remove(key)
    }
  }
}

///|
fn[V] Namespace::end_group(self : Namespace[V]) -> Unit raise ParseFailure {
  match self.undo_stack.pop() {
    Some(changes) => self.restore_group(changes)
    None =>
      raise InternalInvariant(
        message="Unbalanced namespace destruction: attempt to pop global namespace; please report this as a bug",
      )
  }
}

///|
fn[V] Namespace::end_groups(self : Namespace[V]) -> Unit {
  while !self.undo_stack.is_empty() {
    match self.undo_stack.pop() {
      Some(changes) => self.restore_group(changes)
      None => ()
    }
  }
}

///|
fn[V] Namespace::has(self : Namespace[V], key : String) -> Bool {
  self.current.contains(key) || self.builtins.contains(key)
}

///|
fn[V] Namespace::get(self : Namespace[V], key : String) -> V? {
  match self.current.get(key) {
    Some(value) => Some(value)
    None => self.builtins.get(key)
  }
}

///|
fn[V] Namespace::get_current(self : Namespace[V], key : String) -> V? {
  self.current.get(key)
}

///|
fn[V] Namespace::get_builtin(self : Namespace[V], key : String) -> V? {
  self.builtins.get(key)
}

///|
#warnings("-unused_value")
fn[V] Namespace::set(
  self : Namespace[V],
  key : String,
  value : V?,
  global? : Bool = false,
) -> Unit {
  if global {
    for changes in self.undo_stack {
      changes.remove(key)
    }
    match self.undo_stack.last() {
      Some(changes) => changes[key] = value
      None => ()
    }
  } else {
    match self.undo_stack.last() {
      Some(changes) =>
        if !changes.contains(key) {
          changes[key] = self.current.get(key)
        }
      None => ()
    }
  }
  match value {
    Some(v) => self.current[key] = v
    None => self.current.remove(key)
  }
}
