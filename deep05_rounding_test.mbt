///|
fn half_neighbor_library(point : Int, scale : Double) -> @gdsii.GdsLibrary {
  let records = envelope([
    rec(10, 0, b""),
    rec(18, 6, b"leaf"),
    rec(26, 1, b"\x00\x00"),
    rec(27, 5, @gdsii.Real8Raw::from_f64(scale).unwrap().to_bytes()),
    rec(16, 3, xy([(0, 0)])),
    rec(17, 0, b""),
  ])
  let _ = records.pop()
  for
    record in [
      rec(5, 2, Bytes::make(24, 0)),
      rec(6, 6, b"leaf"),
      rec(21, 0, b""),
      rec(13, 2, b"\x00\x07"),
      rec(42, 2, b"\x00\x02"),
      rec(16, 3, xy([(point, 0)])),
      rec(17, 0, b""),
      rec(7, 0, b""),
      rec(4, 0, b""),
    ] {
    records.push(record)
  }
  @gdsii.GdsLibrary::from_records(records).unwrap()
}

///|
test "deep05 positive half predecessor direct" {
  // Exact binary64 value 1/2 - 2^-54, not an approximate decimal oracle.
  let previous = 0x3fdfffffffffffffUL.reinterpret_as_double()
  assert_eq(@gdsii.quantize_dbu(previous).unwrap(), 0)
}

///|
test "deep05 negative half predecessor direct" {
  let previous = 0x3fdfffffffffffffUL.reinterpret_as_double()
  assert_eq(@gdsii.quantize_dbu(-previous).unwrap(), 0)
}

///|
test "deep05 positive half predecessor public flatten" {
  let previous = 0x3fdfffffffffffffUL.reinterpret_as_double()
  let lib = half_neighbor_library(1, previous)
  let flat = lib.flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0].x, 0)
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/leaf:0")
}

///|
test "deep05 negative half predecessor public flatten" {
  let previous = 0x3fdfffffffffffffUL.reinterpret_as_double()
  let flat = half_neighbor_library(-1, previous).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0].x, 0)
}

///|
test "deep05 public flatten final INT32 rounding bounds" {
  let upper_inside = 2147483647.4999998
  let lower_inside = 2147483648.4999995
  assert_eq(
    half_neighbor_library(1, upper_inside).flatten_cell("top").unwrap().shapes[0].points[0].x,
    2147483647,
  )
  assert_eq(
    half_neighbor_library(-1, lower_inside).flatten_cell("top").unwrap().shapes[0].points[0].x,
    -2147483648,
  )
  assert_true(
    half_neighbor_library(1, 2147483647.5).flatten_cell("top")
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    half_neighbor_library(-1, 2147483648.5).flatten_cell("top")
    is Err(@gdsii.CoordinateOverflow(_)),
  )
}

///|
test "deep05 empty AREF instances still consume the expansion budget" {
  let records = envelope([
    rec(11, 0, b""),
    rec(18, 6, b"leaf"),
    rec(19, 2, b"\x00\x03\x00\x02"),
    rec(16, 3, xy([(0, 0), (3, 0), (0, 2)])),
    rec(17, 0, b""),
  ])
  let _ = records.pop()
  for
    record in [
      rec(5, 2, Bytes::make(24, 0)),
      rec(6, 6, b"leaf"),
      rec(7, 0, b""),
      rec(4, 0, b""),
    ] {
    records.push(record)
  }
  let lib = @gdsii.GdsLibrary::from_records(records).unwrap()
  assert_eq(lib.flatten_cell("top", budget=7).unwrap().shapes.length(), 0)
  assert_true(
    lib.flatten_cell("top", budget=6) is Err(@gdsii.ExpansionLimit(6)),
  )
}
