///|
// Private example payload helpers; serialization/checking stays in from_records.
fn int16_payload(values : Array[Int]) -> Bytes {
  let out = @buffer.Buffer()
  for value in values {
    out.write_uint16_be(value.to_uint16())
  }
  out.to_bytes()
}

///|
fn int32_payload(values : Array[Int]) -> Bytes {
  let out = @buffer.Buffer()
  for value in values {
    for shift in [24, 16, 8, 0] {
      out.write_byte(((value >> shift) & 255).to_byte())
    }
  }
  out.to_bytes()
}

///|
fn add_record(
  records : Array[@gdsii.GdsRecord],
  kind : Int,
  data_type : Int,
  data : Bytes,
) -> Unit {
  let offset = if records.is_empty() {
    0
  } else {
    let last = records[records.length() - 1]
    last.offset + last.data.length() + 4
  }
  records.push({ offset, kind, data_type, data, })
}

///|
fn add_rectangle(
  records : Array[@gdsii.GdsRecord],
  box : (Int, Int, Int, Int),
) -> Unit {
  let (x0, y0, x1, y1) = box
  add_record(records, 8, 0, b"") // BOUNDARY
  add_record(records, 13, 2, int16_payload([7])) // LAYER
  add_record(records, 14, 2, int16_payload([2])) // DATATYPE
  add_record(
    records,
    16,
    3,
    int32_payload([x0, y0, x1, y0, x1, y1, x0, y1, x0, y0]),
  ) // closed XY ring, coordinates in DBU
  add_record(records, 17, 0, b"") // ENDEL
}

///|
fn drawing(boxes : Array[(Int, Int, Int, Int)]) -> @gdsii.GdsLibrary {
  let records : Array[@gdsii.GdsRecord] = []
  // Fixed original metadata keeps the example's output deterministic.
  let dates = int16_payload([126, 10, 28, 0, 0, 0, 126, 10, 28, 0, 0, 0])
  add_record(records, 0, 2, int16_payload([600])) // HEADER
  add_record(records, 1, 2, dates) // BGNLIB
  add_record(records, 2, 6, b"AUTHORED") // LIBNAME, even ASCII bytes
  let units = @buffer.Buffer()
  let one = @gdsii.Real8Raw::from_f64(1.0).unwrap().to_bytes()
  units.write_bytes(one) // DBU in user units
  units.write_bytes(one) // DBU in meters; demonstration grid, not a process unit
  add_record(records, 3, 5, units.to_bytes()) // UNITS
  add_record(records, 5, 2, dates) // BGNSTR
  add_record(records, 6, 6, b"top\x00") // STRNAME, padded to even bytes
  for box in boxes {
    add_rectangle(records, box)
  }
  add_record(records, 7, 0, b"") // ENDSTR
  add_record(records, 4, 0, b"") // ENDLIB
  @gdsii.GdsLibrary::from_records(records).unwrap()
}

///|
fn main {
  // Edit these tuples to author your own simple demonstration geometry.
  let before = drawing([(0, 0, 4, 8), (10, 0, 14, 8)])
  let after = drawing([(0, 0, 4, 8), (10, 0, 12, 8)])
  let before_report = before.preflight_cell("top", 7, 2, 3, 5).unwrap()
  let after_report = after.preflight_cell("top", 7, 2, 3, 5).unwrap()
  let result : Json = {
    "schema": "gdsii-author-v1",
    "before": {
      "bytes": [ for byte in before.to_bytes() => byte.to_int() ].to_json(),
      "preflight": before_report.to_json(),
    },
    "after": {
      "bytes": [ for byte in after.to_bytes() => byte.to_int() ].to_json(),
      "preflight": after_report.to_json(),
    },
    "comparison": before_report.diff(after_report).unwrap().to_json(),
  }
  println(result.stringify())
}
