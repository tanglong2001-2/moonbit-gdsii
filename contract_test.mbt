///|
test "REAL8 raw precision, constants, ranges and zero" {
  let raw = @gdsii.Real8Raw::from_bytes([0x41, 0x80, 0, 0, 0, 0, 0, 4]).unwrap()
  assert_eq(raw.to_f64(), 8.0)
  assert_eq(
    @gdsii.Real8Raw::from_f64(raw.to_f64()).unwrap().to_bytes(),
    b"\x41\x80\x00\x00\x00\x00\x00\x00",
  )
  assert_eq(raw.to_bytes(), b"\x41\x80\x00\x00\x00\x00\x00\x04")
  for value in [1.0, 0.001, 0.000000001, -1.0, 0.0, -0.0] {
    let encoded = @gdsii.Real8Raw::from_f64(value).unwrap()
    assert_eq(encoded.to_f64(), value)
    assert_eq(@gdsii.Real8Raw::from_f64(encoded.to_f64()).unwrap(), encoded)
  }
  let maximum = @gdsii.Real8Raw::from_bytes([
    0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
  ]).unwrap()
  assert_true(@gdsii.Real8Raw::from_f64(maximum.to_f64()) is Err(_))
  assert_true(@gdsii.Real8Raw::from_f64(1.0e-300) is Err(_))
  assert_true(@gdsii.Real8Raw::from_f64(1.0e300) is Err(_))
  assert_true(@gdsii.Real8Raw::from_f64(0.0 / 0.0) is Err(_))
  assert_true(@gdsii.Real8Raw::from_f64(1.0 / 0.0) is Err(_))
  assert_true(@gdsii.Real8Raw::from_bytes(b"bad") is Err(_))
  let noncanonical = @gdsii.Real8Raw::from_bytes([0, 0, 0, 0, 0, 0, 0, 1]).unwrap()
  assert_true(noncanonical.to_f64() > 0.0)
  assert_eq(noncanonical.to_bytes(), b"\x00\x00\x00\x00\x00\x00\x00\x01")
}

///|
test "DBU negative ties and bounds" {
  for pair in [(-1.5, -2), (-0.5, -1), (0.5, 1), (1.5, 2)] {
    assert_eq(@gdsii.quantize_dbu(pair.0).unwrap(), pair.1)
  }
  assert_eq(@gdsii.quantize_dbu(-2147483648.49).unwrap(), -2147483648)
  assert_eq(@gdsii.quantize_dbu(2147483647.49).unwrap(), 2147483647)
  assert_true(@gdsii.quantize_dbu(2147483647.5) is Err(_))
  assert_true(@gdsii.quantize_dbu(-2147483648.5) is Err(_))
}

///|
fn rec(kind : Int, data_type : Int, data : Bytes) -> @gdsii.GdsRecord {
  { offset: 0, kind, data_type, data, }
}

///|
fn envelope(elements : Array[@gdsii.GdsRecord]) -> Array[@gdsii.GdsRecord] {
  let rs = [
    rec(0, 2, b"\x02\x58"),
    rec(1, 2, Bytes::make(24, 0)),
    rec(2, 6, b"TEST"),
    rec(
      3, 5, b"\x41\x10\x00\x00\x00\x00\x00\x00\x41\x10\x00\x00\x00\x00\x00\x00",
    ),
    rec(5, 2, Bytes::make(24, 0)),
    rec(6, 6, b"top\x00"),
  ]
  for r in elements {
    rs.push(r)
  }
  rs.push(rec(7, 0, b""))
  rs.push(rec(4, 0, b""))
  rs
}

///|
test "record errors, missing fields, dangling/cyclic references and resource budget" {
  for
    bad in [
      b"", b"\x00\x03\x00\x00", b"\x00\x06\x00\x02\x00", b"\x00\x04\x00\x07",
    ] {
    assert_true(@gdsii.GdsLibrary::parse(bad) is Err(_))
  }
  assert_true(
    @gdsii.GdsLibrary::from_records(envelope([rec(8, 0, b""), rec(17, 0, b"")]))
    is Err(_),
  )
  let reference_records = [
    rec(10, 0, b""),
    rec(18, 6, b"lost"),
    rec(16, 3, Bytes::make(8, 0)),
    rec(17, 0, b""),
  ]
  let lib = @gdsii.GdsLibrary::from_records(envelope(reference_records)).unwrap()
  assert_true(lib.flatten_cell("top") is Err(@gdsii.MissingCell("lost")))
  assert_true(lib.flatten_cell("absent") is Err(@gdsii.MissingCell("absent")))
  assert_true(
    lib.flatten_cell("top", budget=1) is Err(@gdsii.ExpansionLimit(_)),
  )
  let cyclic = @gdsii.GdsLibrary::from_records(
    envelope([
      rec(10, 0, b""),
      rec(18, 6, b"top\x00"),
      rec(16, 3, Bytes::make(8, 0)),
      rec(17, 0, b""),
    ]),
  ).unwrap()
  assert_true(cyclic.flatten_cell("top") is Err(@gdsii.CyclicReference(_)))
}

///|
test "PATH TEXT NODE and unknown properties remain raw and visible" {
  let lib = @gdsii.GdsLibrary::from_records(
    envelope([
      rec(9, 0, b""),
      rec(13, 2, b"\x00\x07"),
      rec(14, 2, b"\x00\x02"),
      rec(15, 3, b"\xff\xff\xff\xfc"),
      rec(
        16, 3, b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0a\x00\x00\x00\x00",
      ),
      rec(43, 2, b"\x00\x01"),
      rec(44, 6, b"metadata"),
      rec(127, 6, b"raw!"),
      rec(17, 0, b""),
      rec(12, 0, b""),
      rec(13, 2, b"\x00\x07"),
      rec(22, 2, b"\x00\x02"),
      rec(16, 3, Bytes::make(8, 0)),
      rec(25, 6, b"label\x00"),
      rec(17, 0, b""),
      rec(21, 0, b""),
      rec(13, 2, b"\x00\x07"),
      rec(42, 2, b"\x00\x02"),
      rec(16, 3, Bytes::make(8, 0)),
      rec(17, 0, b""),
    ]),
  ).unwrap()
  let bytes = lib.to_bytes()
  assert_eq(@gdsii.GdsLibrary::parse(bytes).unwrap().to_bytes(), bytes)
  let flat = lib.flatten_cell("top").unwrap()
  assert_eq(flat.shapes.length(), 3)
  assert_eq(flat.shapes[0].width, 4.0)
  assert_eq(flat.shapes[1].text, "label")
  let selected = flat.rectangles(7, 2)
  assert_eq(selected.rects.length(), 0)
  assert_eq(selected.warnings.length(), 3)
  assert_eq(flat.rectangles(7, 3).warnings.length(), 0)
}

///|
test "raw boxes, threshold equality and geometry errors" {
  let a : @gdsii.Rect = { min_x: 0, min_y: 0, max_x: 2, max_y: 2, source: "a", }
  let b : @gdsii.Rect = { min_x: 5, min_y: 0, max_x: 7, max_y: 2, source: "b", }
  assert_eq(
    @gdsii.check_manhattan_drc([a, b], 2, 3).unwrap().violations.length(),
    0,
  )
  assert_eq(
    @gdsii.check_manhattan_drc([a, a], 2, 1).unwrap().violations.length(),
    1,
  )
  assert_true(@gdsii.check_manhattan_drc([a], -1, 1) is Err(_))
  assert_true(
    @gdsii.check_manhattan_drc(
      [{ min_x: 1, min_y: 0, max_x: 0, max_y: 2, source: "bad", }],
      0,
      0,
    )
    is Err(_),
  )
}

///|
fn xy(points : Array[(Int, Int)]) -> Bytes {
  let b = @buffer.Buffer()
  for p in points {
    b.write_int_be(p.0)
    b.write_int_be(p.1)
  }
  b.to_bytes()
}

///|
test "box identification, field ordering, raw padding and coordinate overflow" {
  let boundary = [
    rec(8, 0, b""),
    rec(13, 2, b"\x00\x07"),
    rec(14, 2, b"\x00\x02"),
    rec(16, 3, xy([(0, 0), (1, 0), (2, 0), (2, 3), (0, 3), (0, 0)])),
    rec(17, 0, b""),
  ]
  let lib = @gdsii.GdsLibrary::from_records(envelope(boundary)).unwrap()
  let selected = lib.flatten_cell("top").unwrap().rectangles(7, 2)
  assert_eq(selected.rects.length(), 1)
  assert_eq(selected.warnings.length(), 0)
  let out = @buffer.Buffer()
  out.write_bytes(lib.to_bytes())
  out.write_bytes(Bytes::make(16, 0))
  assert_eq(
    @gdsii.GdsLibrary::parse(out.to_bytes()).unwrap().to_bytes(),
    out.to_bytes(),
  )
  out.write_byte(1)
  assert_true(@gdsii.GdsLibrary::parse(out.to_bytes()) is Err(_))
  let reversed = boundary.copy()
  reversed[1] = boundary[3]
  reversed[3] = boundary[1]
  assert_true(@gdsii.GdsLibrary::from_records(envelope(reversed)) is Err(_))
  let open = boundary.copy()
  open[3] = rec(16, 3, xy([(0, 0), (2, 0), (2, 3), (0, 3)]))
  assert_true(@gdsii.GdsLibrary::from_records(envelope(open)) is Err(_))
  let bad_scope = boundary.copy()
  bad_scope[2] = rec(22, 2, b"\x00\x02")
  assert_true(@gdsii.GdsLibrary::from_records(envelope(bad_scope)) is Err(_))
  let base = envelope([
    rec(10, 0, b""),
    rec(18, 6, b"leaf"),
    rec(26, 1, b"\x00\x00"),
    rec(27, 5, @gdsii.Real8Raw::from_f64(2.0).unwrap().to_bytes()),
    rec(16, 3, Bytes::make(8, 0)),
    rec(17, 0, b""),
  ])
  let _ = base.pop()
  for
    r in [
      rec(5, 2, Bytes::make(24, 0)),
      rec(6, 6, b"leaf"),
      rec(21, 0, b""),
      rec(13, 2, b"\x00\x07"),
      rec(42, 2, b"\x00\x02"),
      rec(16, 3, xy([(2147483647, 0)])),
      rec(17, 0, b""),
      rec(7, 0, b""),
      rec(4, 0, b""),
    ] {
    base.push(r)
  }
  assert_true(
    @gdsii.GdsLibrary::from_records(base).unwrap().flatten_cell("top")
    is Err(@gdsii.CoordinateOverflow(_)),
  )
}
