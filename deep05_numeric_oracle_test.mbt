///|
test "deep05 exact half-neighbor and INT32 oracle table" {
  assert_eq(
    @gdsii.quantize_dbu(0x3fdfffffffffffffUL.reinterpret_as_double()).unwrap(),
    0,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xbfdfffffffffffffUL.reinterpret_as_double()).unwrap(),
    0,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x3fe0000000000000UL.reinterpret_as_double()).unwrap(),
    1,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xbfe0000000000000UL.reinterpret_as_double()).unwrap(),
    -1,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x3fe0000000000001UL.reinterpret_as_double()).unwrap(),
    1,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xbfe0000000000001UL.reinterpret_as_double()).unwrap(),
    -1,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x3ff7ffffffffffffUL.reinterpret_as_double()).unwrap(),
    1,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xbff7ffffffffffffUL.reinterpret_as_double()).unwrap(),
    -1,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x3ff8000000000000UL.reinterpret_as_double()).unwrap(),
    2,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xbff8000000000000UL.reinterpret_as_double()).unwrap(),
    -2,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x3ff8000000000001UL.reinterpret_as_double()).unwrap(),
    2,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xbff8000000000001UL.reinterpret_as_double()).unwrap(),
    -2,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x4003ffffffffffffUL.reinterpret_as_double()).unwrap(),
    2,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc003ffffffffffffUL.reinterpret_as_double()).unwrap(),
    -2,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x4004000000000000UL.reinterpret_as_double()).unwrap(),
    3,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc004000000000000UL.reinterpret_as_double()).unwrap(),
    -3,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x4004000000000001UL.reinterpret_as_double()).unwrap(),
    3,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc004000000000001UL.reinterpret_as_double()).unwrap(),
    -3,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x408ffbffffffffffUL.reinterpret_as_double()).unwrap(),
    1023,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc08ffbffffffffffUL.reinterpret_as_double()).unwrap(),
    -1023,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x408ffc0000000000UL.reinterpret_as_double()).unwrap(),
    1024,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc08ffc0000000000UL.reinterpret_as_double()).unwrap(),
    -1024,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x408ffc0000000001UL.reinterpret_as_double()).unwrap(),
    1024,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc08ffc0000000001UL.reinterpret_as_double()).unwrap(),
    -1024,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x41dfffffffdfffffUL.reinterpret_as_double()).unwrap(),
    2147483647,
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc1dfffffffdfffffUL.reinterpret_as_double()).unwrap(),
    -2147483647,
  )
  assert_true(
    @gdsii.quantize_dbu(0x41dfffffffe00000UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc1dfffffffe00000UL.reinterpret_as_double()).unwrap(),
    -2147483648,
  )
  assert_true(
    @gdsii.quantize_dbu(0x41dfffffffe00001UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc1dfffffffe00001UL.reinterpret_as_double()).unwrap(),
    -2147483648,
  )
  assert_true(
    @gdsii.quantize_dbu(0x41e00000000fffffUL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_eq(
    @gdsii.quantize_dbu(0xc1e00000000fffffUL.reinterpret_as_double()).unwrap(),
    -2147483648,
  )
  assert_true(
    @gdsii.quantize_dbu(0x41e0000000100000UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    @gdsii.quantize_dbu(0xc1e0000000100000UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    @gdsii.quantize_dbu(0x41e0000000100001UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    @gdsii.quantize_dbu(0xc1e0000000100001UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_eq(
    @gdsii.quantize_dbu(0x0000000000000000UL.reinterpret_as_double()).unwrap(),
    0,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x8000000000000000UL.reinterpret_as_double()).unwrap(),
    0,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x0000000000000001UL.reinterpret_as_double()).unwrap(),
    0,
  )
  assert_eq(
    @gdsii.quantize_dbu(0x8000000000000001UL.reinterpret_as_double()).unwrap(),
    0,
  )
  assert_true(
    @gdsii.quantize_dbu(0x7e37e43c8800759cUL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    @gdsii.quantize_dbu(0xfe37e43c8800759cUL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    @gdsii.quantize_dbu(0x7ff0000000000000UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    @gdsii.quantize_dbu(0xfff0000000000000UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
  assert_true(
    @gdsii.quantize_dbu(0x7ff8000000000000UL.reinterpret_as_double())
    is Err(@gdsii.CoordinateOverflow(_)),
  )
}

///|
test "deep05 exact REAL8 exponent mantissa and raw-zero edges" {
  {
    let b = 0x0000000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0x0000000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2c70000000000000UL)
  }
  {
    let b = 0x000fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2faffffffffffffeUL)
  }
  {
    let b = 0x0010000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2fb0000000000000UL)
  }
  {
    let b = 0x0010000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2fb0000000000001UL)
  }
  {
    let b = 0x001fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2fbfffffffffffffUL)
  }
  {
    let b = 0x0080000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2fe0000000000000UL)
  }
  {
    let b = 0x00ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2ff0000000000000UL)
  }
  {
    let b = 0x0100000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0x0100000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2cb0000000000000UL)
  }
  {
    let b = 0x010fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2feffffffffffffeUL)
  }
  {
    let b = 0x0110000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2ff0000000000000UL)
  }
  {
    let b = 0x0110000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2ff0000000000001UL)
  }
  {
    let b = 0x011fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x2fffffffffffffffUL)
  }
  {
    let b = 0x0180000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3020000000000000UL)
  }
  {
    let b = 0x01ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3030000000000000UL)
  }
  {
    let b = 0x4000000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0x4000000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3c70000000000000UL)
  }
  {
    let b = 0x400fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3faffffffffffffeUL)
  }
  {
    let b = 0x4010000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3fb0000000000000UL)
  }
  {
    let b = 0x4010000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3fb0000000000001UL)
  }
  {
    let b = 0x401fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3fbfffffffffffffUL)
  }
  {
    let b = 0x4080000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3fe0000000000000UL)
  }
  {
    let b = 0x40ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3ff0000000000000UL)
  }
  {
    let b = 0x4100000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0x4100000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3cb0000000000000UL)
  }
  {
    let b = 0x410fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3feffffffffffffeUL)
  }
  {
    let b = 0x4110000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3ff0000000000000UL)
  }
  {
    let b = 0x4110000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3ff0000000000001UL)
  }
  {
    let b = 0x411fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x3fffffffffffffffUL)
  }
  {
    let b = 0x4180000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4020000000000000UL)
  }
  {
    let b = 0x41ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4030000000000000UL)
  }
  {
    let b = 0x7f00000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0x7f00000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4c30000000000000UL)
  }
  {
    let b = 0x7f0fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4f6ffffffffffffeUL)
  }
  {
    let b = 0x7f10000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4f70000000000000UL)
  }
  {
    let b = 0x7f10000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4f70000000000001UL)
  }
  {
    let b = 0x7f1fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4f7fffffffffffffUL)
  }
  {
    let b = 0x7f80000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4fa0000000000000UL)
  }
  {
    let b = 0x7fffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x4fb0000000000000UL)
  }
  {
    let b = 0x8000000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0x8000000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xac70000000000000UL)
  }
  {
    let b = 0x800fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xafaffffffffffffeUL)
  }
  {
    let b = 0x8010000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xafb0000000000000UL)
  }
  {
    let b = 0x8010000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xafb0000000000001UL)
  }
  {
    let b = 0x801fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xafbfffffffffffffUL)
  }
  {
    let b = 0x8080000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xafe0000000000000UL)
  }
  {
    let b = 0x80ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xaff0000000000000UL)
  }
  {
    let b = 0x8100000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0x8100000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xacb0000000000000UL)
  }
  {
    let b = 0x810fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xafeffffffffffffeUL)
  }
  {
    let b = 0x8110000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xaff0000000000000UL)
  }
  {
    let b = 0x8110000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xaff0000000000001UL)
  }
  {
    let b = 0x811fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xafffffffffffffffUL)
  }
  {
    let b = 0x8180000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xb020000000000000UL)
  }
  {
    let b = 0x81ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xb030000000000000UL)
  }
  {
    let b = 0xc000000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0xc000000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbc70000000000000UL)
  }
  {
    let b = 0xc00fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbfaffffffffffffeUL)
  }
  {
    let b = 0xc010000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbfb0000000000000UL)
  }
  {
    let b = 0xc010000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbfb0000000000001UL)
  }
  {
    let b = 0xc01fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbfbfffffffffffffUL)
  }
  {
    let b = 0xc080000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbfe0000000000000UL)
  }
  {
    let b = 0xc0ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbff0000000000000UL)
  }
  {
    let b = 0xc100000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0xc100000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbcb0000000000000UL)
  }
  {
    let b = 0xc10fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbfeffffffffffffeUL)
  }
  {
    let b = 0xc110000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbff0000000000000UL)
  }
  {
    let b = 0xc110000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbff0000000000001UL)
  }
  {
    let b = 0xc11fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xbfffffffffffffffUL)
  }
  {
    let b = 0xc180000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xc020000000000000UL)
  }
  {
    let b = 0xc1ffffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xc030000000000000UL)
  }
  {
    let b = 0xff00000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0x0000000000000000UL)
  }
  {
    let b = 0xff00000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xcc30000000000000UL)
  }
  {
    let b = 0xff0fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xcf6ffffffffffffeUL)
  }
  {
    let b = 0xff10000000000000UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xcf70000000000000UL)
  }
  {
    let b = 0xff10000000000001UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xcf70000000000001UL)
  }
  {
    let b = 0xff1fffffffffffffUL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xcf7fffffffffffffUL)
  }
  {
    let b = 0xff80000000000004UL.to_be_bytes()
    let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
    assert_eq(raw.to_bytes(), b)
    assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xcfa0000000000000UL)
  }
  let b = 0xffffffffffffffffUL.to_be_bytes()
  let raw = @gdsii.Real8Raw::from_bytes(b).unwrap()
  assert_eq(raw.to_bytes(), b)
  assert_eq(raw.to_f64().reinterpret_as_uint64(), 0xcfb0000000000000UL)
}

///|
test "deep05 exact REAL8 normalized encoding boundaries" {
  assert_true(
    @gdsii.Real8Raw::from_f64(0x2fafffffffffffffUL.reinterpret_as_double())
    is Err(@gdsii.InvalidNumber(_)),
  )
  assert_true(
    @gdsii.Real8Raw::from_f64(0xafafffffffffffffUL.reinterpret_as_double())
    is Err(@gdsii.InvalidNumber(_)),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x2fb0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x0010000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xafb0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x8010000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x2fb0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x0010000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xafb0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x8010000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x2fefffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x00fffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xafefffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x80fffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x2ff0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x0110000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xaff0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x8110000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x2ff0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x0110000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xaff0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x8110000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x3fafffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x3ffffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xbfafffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xbffffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x3fb0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x4010000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xbfb0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc010000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x3fb0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x4010000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xbfb0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc010000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x3fefffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x40fffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xbfefffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc0fffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x3ff0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x4110000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xbff0000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc110000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x3ff0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x4110000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xbff0000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc110000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x402fffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x41fffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xc02fffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc1fffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x4030000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x4210000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xc030000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc210000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x4030000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x4210000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xc030000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xc210000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x4f6fffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x7efffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xcf6fffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xfefffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x4f70000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x7f10000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xcf70000000000000UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xff10000000000000UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x4f70000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x7f10000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xcf70000000000001UL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xff10000000000001UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0x4fafffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0x7ffffffffffffff8UL.to_be_bytes(),
  )
  assert_eq(
    @gdsii.Real8Raw::from_f64(0xcfafffffffffffffUL.reinterpret_as_double())
    .unwrap()
    .to_bytes(),
    0xfffffffffffffff8UL.to_be_bytes(),
  )
  assert_true(
    @gdsii.Real8Raw::from_f64(0x4fb0000000000000UL.reinterpret_as_double())
    is Err(@gdsii.InvalidNumber(_)),
  )
  assert_true(
    @gdsii.Real8Raw::from_f64(0xcfb0000000000000UL.reinterpret_as_double())
    is Err(@gdsii.InvalidNumber(_)),
  )
  assert_true(
    @gdsii.Real8Raw::from_f64(0x4fb0000000000001UL.reinterpret_as_double())
    is Err(@gdsii.InvalidNumber(_)),
  )
  assert_true(
    @gdsii.Real8Raw::from_f64(0xcfb0000000000001UL.reinterpret_as_double())
    is Err(@gdsii.InvalidNumber(_)),
  )
}
