///|
test "deep07 exact raw-angle periodic boundary table" {
  {
    let raw = 0x0000000000000000UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x0000000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x8000000000000000UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x0000000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x0000000000000001UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x2c70000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x8000000000000001UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0xac70000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x4010000000000000UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x3fb0000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x40ffffffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x3ff0000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x41ffffffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x4030000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x43167fffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0xbd30000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x4316800000000000UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x0000000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x4316800000000001UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x3d30000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0xc3167fffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x3d30000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0xc316800000000000UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x0000000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0xc316800000000001UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0xbd30000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x4dffffffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x402fe00000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x4effffffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0xc05a400000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x4fffffffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x405e000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x7f00000000000001UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x4030000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x7f10000000000000UL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0xc05a000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  {
    let raw = 0x7fffffffffffffffUL.to_be_bytes()
    let lib = deep07_oriented(raw, 0, 0, 1.0)
    let flat = lib.flatten_cell("top").unwrap()
    assert_eq(
      flat.shapes[0].angle,
      0x405e000000000000UL.reinterpret_as_double(),
    )
    assert_eq(
      lib.cells()[0].elements[0].placement.angle,
      @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
    )
  }
  let raw = 0xffffffffffffffffUL.to_be_bytes()
  let lib = deep07_oriented(raw, 0, 0, 1.0)
  let flat = lib.flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].angle, 0xc05e000000000000UL.reinterpret_as_double())
  assert_eq(
    lib.cells()[0].elements[0].placement.angle,
    @gdsii.Real8Raw::from_bytes(raw).unwrap().to_f64(),
  )
}

///|
test "deep07 large-angle nested absolute controls r0-a0-m0" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x00])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x00, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: -137, y: -37, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
test "deep07 large-angle nested absolute controls r0-a0-m1" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x04])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x00, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: -68, y: -18, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
test "deep07 large-angle nested absolute controls r0-a1-m0" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x02])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x00, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: 37, y: 137, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
test "deep07 large-angle nested absolute controls r0-a1-m1" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x06])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x00, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: 18, y: 68, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
test "deep07 large-angle nested absolute controls r1-a0-m0" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x00])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x80, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: 100, y: 100, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
test "deep07 large-angle nested absolute controls r1-a0-m1" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x04])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x80, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: 50, y: 50, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
test "deep07 large-angle nested absolute controls r1-a1-m0" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x02])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x80, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: 137, y: -37, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}

///|
test "deep07 large-angle nested absolute controls r1-a1-m1" {
  let child = deep07_reference(
    b"leaf",
    @gdsii.Real8Raw::from_f64(30.0).unwrap().to_bytes(),
    0.5,
  )
  child[2] = rec(26, 1, [0x00, 0x06])
  let cells = deep07_cell(b"mid\x00", child)
  for r in deep07_cell(b"leaf", deep07_node(100, 100)) {
    cells.push(r)
  }
  let parent = deep07_reference(
    b"mid\x00",
    0x7fffffffffffffffUL.to_be_bytes(),
    2.0,
  )
  parent[2] = rec(26, 1, [0x80, 0x00])
  let flat = deep07_library(parent, cells).flatten_cell("top").unwrap()
  assert_eq(flat.shapes[0].points[0], @gdsii.Point::{ x: 68, y: -18, })
  assert_eq(flat.shapes[0].source, "/top:0[0,0]/mid:0[0,0]/leaf:0")
}
