///|
test "parse simple math symbols" {
  debug_inspect(
    parse("x+1"),
    content=(
      #|Ok(
      #|  [
      #|    MathOrd(
      #|      mode=Math,
      #|      loc=Some({ input: "x+1", start: 0, end: 1 }),
      #|      text="x",
      #|    ),
      #|    Atom(
      #|      mode=Math,
      #|      loc=Some({ input: "x+1", start: 1, end: 2 }),
      #|      family=Mbin,
      #|      text="+",
      #|    ),
      #|    MathOrd(
      #|      mode=Math,
      #|      loc=Some({ input: "x+1", start: 2, end: 3 }),
      #|      text="1",
      #|    ),
      #|  ],
      #|)
    ),
  )
}

///|
test "parse superscript" {
  debug_inspect(
    parse("x^2"),
    content=(
      #|Ok(
      #|  [
      #|    SupSub(
      #|      mode=Math,
      #|      base=Some(
      #|        MathOrd(
      #|          mode=Math,
      #|          loc=Some({ input: "x^2", start: 0, end: 1 }),
      #|          text="x",
      #|        ),
      #|      ),
      #|      sup=Some(
      #|        MathOrd(
      #|          mode=Math,
      #|          loc=Some({ input: "x^2", start: 2, end: 3 }),
      #|          text="2",
      #|        ),
      #|      ),
      #|      sub=None,
      #|    ),
      #|  ],
      #|)
    ),
  )
}

///|
test "parse braced group" {
  debug_inspect(
    parse("{xy}"),
    content=(
      #|Ok(
      #|  [
      #|    OrdGroup(
      #|      mode=Math,
      #|      loc=Some({ input: "{xy}", start: 0, end: 4 }),
      #|      body=[
      #|        MathOrd(
      #|          mode=Math,
      #|          loc=Some({ input: "{xy}", start: 1, end: 2 }),
      #|          text="x",
      #|        ),
      #|        MathOrd(
      #|          mode=Math,
      #|          loc=Some({ input: "{xy}", start: 2, end: 3 }),
      #|          text="y",
      #|        ),
      #|      ],
      #|      semisimple=false,
      #|    ),
      #|  ],
      #|)
    ),
  )
}
