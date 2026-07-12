///|
test "Namespace uses initial map as mutable global storage" {
  let globals : Map[String, Int] = { "a": 1 }
  let ns = Namespace::make(Map([]), globals)
  ns.set("a", Some(2))
  ns.set("b", Some(3))
  assert_eq(globals.get("a"), Some(2))
  assert_eq(globals.get("b"), Some(3))
  ns.set("a", None)
  assert_false(globals.contains("a"))
}

///|
test "Namespace local sets restore first value at group end" {
  let ns = Namespace::make(Map([]), { "a": 1 })
  ns.begin_group()
  ns.set("a", Some(2))
  ns.set("a", Some(3))
  ns.set("b", Some(4))
  assert_eq((ns.get("a"), ns.get("b")), (Some(3), Some(4)))
  ns.end_group().unwrap()
  assert_eq((ns.get("a"), ns.get("b")), (Some(1), None))
}

///|
test "Namespace deletion exposes builtin and restores global override" {
  let ns = Namespace::make({ "a": 1 }, { "a": 2 })
  ns.begin_group()
  ns.set("a", None)
  assert_true(ns.has("a"))
  assert_eq(ns.get("a"), Some(1))
  ns.end_group().unwrap()
  assert_eq(ns.get("a"), Some(2))
}

///|
test "Namespace local builtin override restores builtin" {
  let ns = Namespace::make({ "a": 1 }, Map([]))
  ns.begin_group()
  ns.set("a", Some(2))
  assert_eq(ns.get("a"), Some(2))
  ns.end_group().unwrap()
  assert_eq(ns.get("a"), Some(1))
}

///|
test "Namespace global set survives every surrounding group" {
  let globals : Map[String, Int] = { "a": 0 }
  let ns = Namespace::make(Map([]), globals)
  ns.begin_group()
  ns.set("a", Some(1))
  ns.begin_group()
  ns.set("a", Some(2))
  ns.set("a", Some(3), global=true)
  ns.set("a", Some(4))
  assert_eq(ns.get("a"), Some(4))
  ns.end_group().unwrap()
  assert_eq(ns.get("a"), Some(3))
  ns.end_group().unwrap()
  assert_eq(ns.get("a"), Some(3))
  assert_eq(globals.get("a"), Some(3))
}

///|
test "Namespace global deletion survives every surrounding group" {
  let globals : Map[String, Int] = { "a": 0 }
  let ns = Namespace::make({ "a": 9 }, globals)
  ns.begin_group()
  ns.set("a", Some(1))
  ns.begin_group()
  ns.set("a", None, global=true)
  ns.set("a", Some(2))
  assert_eq(ns.get("a"), Some(2))
  ns.end_group().unwrap()
  assert_eq(ns.get("a"), Some(9))
  ns.end_group().unwrap()
  assert_eq(ns.get("a"), Some(9))
  assert_false(globals.contains("a"))
}

///|
test "Namespace end_groups restores all local changes" {
  let ns = Namespace::make(Map([]), { "a": 0 })
  ns.begin_group()
  ns.set("a", Some(1))
  ns.begin_group()
  ns.set("a", Some(2))
  ns.set("b", Some(3))
  ns.end_groups()
  assert_eq((ns.get("a"), ns.get("b")), (Some(0), None))
}

///|
test "Namespace rejects ending the global namespace" {
  let ns : Namespace[Int] = Namespace::make(Map([]), Map([]))
  match ns.end_group() {
    Err(InternalInvariant(message~)) =>
      assert_eq(
        message, "Unbalanced namespace destruction: attempt to pop global namespace; please report this as a bug",
      )
    _ => fail("expected InternalInvariant")
  }
}
