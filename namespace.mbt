///|
pub(all) struct Namespace[V] {
  builtins : Map[String, V]
  current : Map[String, V]
  stack : Array[Map[String, V?]]
} derive(Debug)

///|
pub fn[V] Namespace::make(
  builtins : Map[String, V],
  initial : Map[String, V],
) -> Namespace[V] {
  { builtins, current: initial, stack: [] }
}

///|
pub fn[V] Namespace::begin_group(self : Namespace[V]) -> Unit {
  self.stack.push({})
}

///|
pub fn[V] Namespace::end_group(self : Namespace[V]) -> Unit {
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
pub fn[V] Namespace::end_groups(self : Namespace[V]) -> Unit {
  while !self.stack.is_empty() {
    self.end_group()
  }
}

///|
pub fn[V] Namespace::get(self : Namespace[V], key : String) -> V? {
  match self.current.get(key) {
    Some(value) => Some(value)
    None => self.builtins.get(key)
  }
}

///|
pub fn[V] Namespace::has(self : Namespace[V], key : String) -> Bool {
  self.current.contains(key) || self.builtins.contains(key)
}

///|
pub fn[V] Namespace::set(
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
    Some(v) => self.current[key] = v
    None => self.current.remove(key)
  }
}
