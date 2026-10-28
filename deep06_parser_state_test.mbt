///|
fn deep06_empty_records() -> Array[@gdsii.GdsRecord] {
  [
    rec(0, 2, b"\x02\x58"),
    rec(1, 2, Bytes::make(24, 0)),
    rec(2, 6, b"EMPTY\x00"),
    rec(
      3, 5, b"\x41\x10\x00\x00\x00\x00\x00\x00\x41\x10\x00\x00\x00\x00\x00\x00",
    ),
    rec(4, 0, b""),
  ]
}

///|
fn deep06_record_bytes(records : Array[@gdsii.GdsRecord]) -> Bytes {
  let bytes = @buffer.Buffer()
  for r in records {
    bytes.write_uint16_be((r.data.length() + 4).to_uint16())
    bytes.write_byte(r.kind.to_byte())
    bytes.write_byte(r.data_type.to_byte())
    bytes.write_bytes(r.data)
  }
  bytes.to_bytes()
}

///|
test "deep06 legal five-record empty library parses and rewrites" {
  let bytes = deep06_record_bytes(deep06_empty_records())
  let library = @gdsii.GdsLibrary::parse(bytes).unwrap()
  assert_eq(library.name(), "EMPTY")
  assert_eq(library.cells().length(), 0)
  assert_eq(library.records().length(), 5)
  assert_eq(library.to_bytes(), bytes)
  assert_true(library.flatten_cell("top") is Err(@gdsii.MissingCell("top")))
  assert_eq(
    @gdsii.GdsLibrary::from_records(deep06_empty_records()).unwrap().to_bytes(),
    bytes,
  )
  let padded = @buffer.Buffer()
  padded.write_bytes(bytes)
  padded.write_bytes(Bytes::make(32, 0))
  assert_eq(
    @gdsii.GdsLibrary::parse(padded.to_bytes()).unwrap().to_bytes(),
    padded.to_bytes(),
  )
}

///|
fn deep06_attribute_records() -> Array[@gdsii.GdsRecord] {
  [
    rec(23, 1, b"\x00\x00"),
    rec(33, 2, b"\x00\x04"),
    rec(38, 1, b"\x00\x00"),
    rec(43, 2, b"\x00\x01"),
    rec(44, 6, b"value\x00"),
    rec(47, 3, b"\x00\x00\x00\x01"),
    rec(48, 3, b"\x00\x00\x00\x02"),
    rec(49, 3, b"\x00\x00\x00\x03"),
  ]
}

///|
test "deep06 known element attributes cannot stand alone in a cell" {
  for attribute in deep06_attribute_records() {
    let records = envelope([attribute])
    let offset = deep06_record_bytes(records[:6].to_owned()).length()
    let result = @gdsii.GdsLibrary::from_records(records)
    guard result is Err(@gdsii.InvalidStructure(actual_offset, _)) else {
      fail("accepted misplaced element attribute")
    }
    assert_eq(actual_offset, offset)
  }
}

///|
test "deep06 known element attributes cannot stand alone in library scope" {
  for attribute in deep06_attribute_records() {
    let records = deep06_empty_records()
    let _ = records.pop()
    let offset = deep06_record_bytes(records).length()
    records.push(attribute)
    records.push(rec(4, 0, b""))
    let result = @gdsii.GdsLibrary::from_records(records)
    guard result is Err(@gdsii.InvalidStructure(actual_offset, _)) else {
      fail("accepted attribute in library scope")
    }
    assert_eq(actual_offset, offset)
  }
}

///|
test "deep06 known header records cannot hide as unknown element extensions" {
  let headers = deep06_empty_records()
  for header in headers[:4] {
    let fields = [
      rec(8, 0, b""),
      rec(13, 2, b"\x00\x07"),
      rec(14, 2, b"\x00\x02"),
      rec(16, 3, xy([(0, 0), (2, 0), (2, 2), (0, 2), (0, 0)])),
    ]
    let prefix = envelope(fields)
    let offset = deep06_record_bytes(prefix[:prefix.length() - 2].to_owned()).length()
    fields.push(header)
    fields.push(rec(17, 0, b""))
    let result = @gdsii.GdsLibrary::from_records(envelope(fields))
    guard result is Err(@gdsii.InvalidStructure(actual_offset, _)) else {
      fail("accepted header inside boundary")
    }
    assert_eq(actual_offset, offset)
  }
}

///|
test "deep06 unknown records and valid attributed PATH TEXT remain accepted" {
  let fields = [
    rec(9, 0, b""),
    rec(38, 1, b"\x00\x00"),
    rec(47, 3, b"\x00\x00\x00\x01"),
    rec(13, 2, b"\x00\x07"),
    rec(14, 2, b"\x00\x02"),
    rec(33, 2, b"\x00\x04"),
    rec(15, 3, b"\xff\xff\xff\xfc"),
    rec(48, 3, b"\xff\xff\xff\xfe"),
    rec(49, 3, b"\x00\x00\x00\x03"),
    rec(16, 3, xy([(0, 0), (8, 0)])),
    rec(43, 2, b"\x00\x01"),
    rec(44, 6, b"first\x00"),
    rec(43, 2, b"\x00\x02"),
    rec(44, 6, b"second"),
    rec(127, 6, b"vendor"),
    rec(17, 0, b""),
    rec(12, 0, b""),
    rec(13, 2, b"\x00\x07"),
    rec(22, 2, b"\x00\x02"),
    rec(23, 1, b"\x00\x05"),
    rec(16, 3, xy([(3, 4)])),
    rec(25, 6, b"label\x00"),
    rec(17, 0, b""),
  ]
  let records = envelope(fields)
  let bytes = deep06_record_bytes(records)
  let lib = @gdsii.GdsLibrary::parse(bytes).unwrap()
  assert_eq(lib.to_bytes(), bytes)
  let shapes = lib.flatten_cell("top").unwrap().shapes
  assert_eq(shapes.length(), 2)
  assert_eq(shapes[0].width, 4.0)
  assert_eq(shapes[0].begin_extension, -2.0)
  assert_eq(shapes[0].end_extension, 3.0)
  assert_eq(shapes[1].text, "label")
  let empty = deep06_empty_records()
  let _ = empty.pop()
  empty.push(rec(127, 6, b"vendor"))
  empty.push(rec(4, 0, b""))
  assert_eq(@gdsii.GdsLibrary::from_records(empty).unwrap().cells().length(), 0)
}

///|
test "deep06 repeated unknown extensions retain bytes without invented uniqueness" {
  let fields = [
    rec(21, 0, b""),
    rec(13, 2, b"\x00\x07"),
    rec(42, 2, b"\x00\x02"),
    rec(16, 3, xy([(2, 3)])),
    rec(127, 6, b"part-1"),
    rec(127, 6, b"part-2"),
    rec(17, 0, b""),
  ]
  let bytes = deep06_record_bytes(envelope(fields))
  let lib = @gdsii.GdsLibrary::parse(bytes).unwrap()
  assert_eq(lib.to_bytes(), bytes)
  assert_eq(lib.cells()[0].elements[0].records[4].data, b"part-1")
  assert_eq(lib.cells()[0].elements[0].records[5].data, b"part-2")
  let bad = [
    rec(21, 0, b""),
    rec(13, 2, b"\x00\x07"),
    rec(13, 2, b"\x00\x07"),
    rec(42, 2, b"\x00\x02"),
    rec(16, 3, xy([(2, 3)])),
    rec(17, 0, b""),
  ]
  assert_true(
    @gdsii.GdsLibrary::from_records(envelope(bad))
    is Err(@gdsii.InvalidStructure(_, "duplicate element field")),
  )
}
