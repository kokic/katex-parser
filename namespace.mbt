///|
priv struct Namespace[V] {
  builtins : Map[String, V]
  current : Map[String, NamespaceBinding[V]]
  stack : Array[Map[String, NamespaceBinding[V]?]]
}

///|
priv enum NamespaceBinding[V] {
  Bound(V)
  Deleted
}

///|
fn[V] Namespace::make(
  builtins : Map[String, V],
  initial : Map[String, V],
) -> Namespace[V] {
  let ns : Namespace[V] = { builtins, current: Map([]), stack: [] }
  initial.each((key, value) => ns.set(key, Some(value), global=true))
  ns
}

///|
fn[V] Namespace::begin_group(self : Namespace[V]) -> Unit {
  self.stack.push(Map([]))
}

///|
fn[V] Namespace::end_group(self : Namespace[V]) -> Unit {
  match self.stack.pop() {
    Some(changes) =>
      for key, old_value in changes {
        match old_value {
          Some(value) => self.current[key] = value
          None => self.current.remove(key)
        }
      }
    None => ()
  }
}

///|
fn[V] Namespace::end_groups(self : Namespace[V]) -> Unit {
  while !self.stack.is_empty() {
    self.end_group()
  }
}

///|
fn[V] Namespace::get(self : Namespace[V], key : String) -> V? {
  match self.current.get(key) {
    Some(Bound(value)) => Some(value)
    Some(Deleted) => None
    None => self.builtins.get(key)
  }
}

///|
fn[V] Namespace::has(self : Namespace[V], key : String) -> Bool {
  self.get(key) is Some(_)
}

///|
fn[V] Namespace::set(
  self : Namespace[V],
  key : String,
  value : V?,
  global? : Bool = false,
) -> Unit {
  if !global {
    match self.stack.last() {
      Some(changes) =>
        if !changes.contains(key) {
          changes[key] = self.current.get(key)
        }
      None => ()
    }
  }
  match value {
    Some(v) => self.current[key] = Bound(v)
    None => self.current[key] = Deleted
  }
}
