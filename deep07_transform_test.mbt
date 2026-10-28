///|
fn deep07_cell(
  name : Bytes,
  fields : Array[@gdsii.GdsRecord],
) -> Array[@gdsii.GdsRecord] {
  let records = [rec(5, 2, Bytes::make(24, 0)), rec(6, 6, name)]
  for field in fields {
    records.push(field)
  }
  records.push(rec(7, 0, b""))
  records
}

///|
fn deep07_reference(
  target : Bytes,
  angle : Bytes,
  mag : Double,
) -> Array[@gdsii.GdsRecord] {
  [
    rec(10, 0, b""),
    rec(18, 6, target),
    rec(26, 1, b"\x00\x00"),
    rec(27, 5, @gdsii.Real8Raw::from_f64(mag).unwrap().to_bytes()),
    rec(28, 5, angle),
    rec(16, 3, xy([(0, 0)])),
    rec(17, 0, b""),
  ]
}

///|
fn deep07_node(x : Int, y : Int) -> Array[@gdsii.GdsRecord] {
  [
    rec(21, 0, b""),
    rec(13, 2, b"\x00\x07"),
    rec(42, 2, b"\x00\x02"),
    rec(16, 3, xy([(x, y)])),
    rec(17, 0, b""),
  ]
}

///|
fn deep07_library(
  top : Array[@gdsii.GdsRecord],
  cells : Array[@gdsii.GdsRecord],
) -> @gdsii.GdsLibrary {
  let records = envelope(top)
  let _ = records.pop()
  for record in cells {
    records.push(record)
  }
  records.push(rec(4, 0, b""))
  @gdsii.GdsLibrary::from_records(records).unwrap()
}

///|
fn deep07_oriented(
  angle : Bytes,
  x : Int,
  y : Int,
  mag : Double,
) -> @gdsii.GdsLibrary {
  deep07_library(
    deep07_reference(b"leaf", angle, mag),
    deep07_cell(b"leaf", deep07_node(x, y)),
  )
}

///|
test "deep07 full turns preserve the half-grid orientation" {
  for angle in [0.0, 360.0, -360.0, 720.0, -720.0] {
    let raw = @gdsii.Real8Raw::from_f64(angle).unwrap().to_bytes()
    let lib = deep07_oriented(raw, 1, 1, 0.5)
    let p = lib.flatten_cell("top").unwrap().shapes[0].points[0]
    assert_eq(p, @gdsii.Point::{ x: 1, y: 1, })
  }
}

///|
test "deep07 raw REAL8 angle keeps exact full-turn remainder" {
  // (2^56-1)*2^196 has remainder 120 degrees, not the remainder
  // of the already-rounded binary64 value 2^252.
  let raw = 0x7fffffffffffffffUL.to_be_bytes()
  let lib = deep07_oriented(raw, 100, 0, 1.0)
  let bytes = lib.to_bytes()
  let shape = lib.flatten_cell("top").unwrap().shapes[0]
  assert_eq(shape.points[0], @gdsii.Point::{ x: -50, y: 87, })
  assert_eq(shape.angle, 120.0)
  assert_eq(
    lib.cells()[0].elements[0].placement.angle,
    @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
  )
  assert_eq(lib.to_bytes(), bytes)
}

///|
test "deep07 large parent angle does not swallow relative child angle" {
  let cells = deep07_cell(
    b"mid\x00",
    deep07_reference(
      b"leaf",
      @gdsii.Real8Raw::from_f64(60.0).unwrap().to_bytes(),
      1.0,
    ),
  )
  for record in deep07_cell(b"leaf", deep07_node(100, 0)) {
    cells.push(record)
  }
  let lib = deep07_library(
    deep07_reference(b"mid\x00", 0x7fffffffffffffffUL.to_be_bytes(), 1.0),
    cells,
  )
  let shape = lib.flatten_cell("top").unwrap().shapes[0]
  assert_eq(shape.points[0], @gdsii.Point::{ x: -100, y: 0, })
  assert_eq(shape.source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
fn deep07_large_frame(fields : Array[@gdsii.GdsRecord]) -> @gdsii.GdsLibrary {
  let huge = 0x4f90000000000000UL.reinterpret_as_double() // 2^250
  let zero = @gdsii.Real8Raw::from_f64(0.0).unwrap().to_bytes()
  let cells = []
  for item in [(b"c1", b"c2"), (b"c2", b"c3"), (b"c3", b"leaf")] {
    for record in deep07_cell(item.0, deep07_reference(item.1, zero, huge)) {
      cells.push(record)
    }
  }
  for record in deep07_cell(b"leaf", fields) {
    cells.push(record)
  }
  deep07_library(deep07_reference(b"c1", zero, huge), cells)
}

///|
fn deep07_path(
  width : Int,
  begin_extension : Int,
  end_extension : Int,
) -> Array[@gdsii.GdsRecord] {
  let value = @buffer.Buffer()
  value.write_int_be(width)
  let begin = @buffer.Buffer()
  begin.write_int_be(begin_extension)
  let end = @buffer.Buffer()
  end.write_int_be(end_extension)
  [
    rec(9, 0, b""),
    rec(13, 2, b"\x00\x07"),
    rec(14, 2, b"\x00\x02"),
    rec(33, 2, b"\x00\x04"),
    rec(15, 3, value.to_bytes()),
    rec(48, 3, begin.to_bytes()),
    rec(49, 3, end.to_bytes()),
    rec(16, 3, xy([(0, 0), (0, 0)])),
    rec(17, 0, b""),
  ]
}

///|
test "deep07 overflowing transformed PATH width is not a successful layout" {
  let result = deep07_large_frame(deep07_path(2147483647, 0, 0)).flatten_cell(
    "top",
  )
  assert_true(result is Err(@gdsii.InvalidNumber(_)))
}

///|
test "deep07 overflowing transformed PATH extensions are errors" {
  for values in [(2147483647, 0), (0, -2147483648)] {
    let result = deep07_large_frame(deep07_path(-4, values.0, values.1)).flatten_cell(
      "top",
    )
    assert_true(result is Err(@gdsii.InvalidNumber(_)))
  }
}

///|
fn deep07_text(absolute : Bool) -> Array[@gdsii.GdsRecord] {
  let mag = 0x4630000000000000UL.reinterpret_as_double() // 2^100
  [
    rec(12, 0, b""),
    rec(13, 2, b"\x00\x07"),
    rec(22, 2, b"\x00\x02"),
    rec(26, 1, if absolute { b"\x00\x04" } else { b"\x00\x00" }),
    rec(27, 5, @gdsii.Real8Raw::from_f64(mag).unwrap().to_bytes()),
    rec(16, 3, xy([(0, 0)])),
    rec(25, 6, b"label\x00"),
    rec(17, 0, b""),
  ]
}

///|
test "deep07 overflowing TEXT magnification is an error" {
  assert_true(
    deep07_large_frame(deep07_text(false)).flatten_cell("top")
    is Err(@gdsii.InvalidNumber(_)),
  )
}

///|
test "deep07 finite large metadata and absolute text magnitude stay supported" {
  let absolute_path = deep07_large_frame(deep07_path(-2147483648, 0, 0))
    .flatten_cell("top")
    .unwrap().shapes[0]
  assert_eq(absolute_path.width, 2147483648.0)
  let relative_path = deep07_large_frame(deep07_path(1, 0, 0))
    .flatten_cell("top")
    .unwrap().shapes[0]
  assert_eq(relative_path.width, 0x7e70000000000000UL.reinterpret_as_double()) // 2^1000
  let text = deep07_large_frame(deep07_text(true)).flatten_cell("top").unwrap().shapes[0]
  assert_eq(text.magnification, 0x4630000000000000UL.reinterpret_as_double())
}
