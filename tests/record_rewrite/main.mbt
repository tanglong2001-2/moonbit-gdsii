///|
// Test-only public-API consumer. These are complete, original GDS record bytes;
// no GDS writer or floating-point conversion builds this input fixture.
fn original_file() -> Bytes {
  let out = @buffer.Buffer()
  for
    record in [
      b"\x00\x06\x00\x02\x02\x58", // HEADER 600
       b"\x00\x1c\x01\x02\x00\x7e\x00\x0a\x00\x1d\x00\x04\x00\x00\x00\x00\x00\x7e\x00\x0a\x00\x1d\x00\x04\x00\x00\x00\x00", // BGNLIB
       b"\x00\x0c\x02\x06REWRITE\x00", // LIBNAME
       b"\x00\x14\x03\x05\x41\x80\x00\x00\x00\x00\x00\x04\x41\x10\x00\x00\x00\x00\x00\x01", // UNITS, fraction bits lost through Double
       b"\x00\x1c\x05\x02\x00\x7e\x00\x0a\x00\x1d\x00\x04\x00\x00\x00\x00\x00\x7e\x00\x0a\x00\x1d\x00\x04\x00\x00\x00\x00", // BGNSTR
       b"\x00\x08\x06\x06top\x00", // STRNAME
       b"\x00\x04\x08\x00", // BOUNDARY
       b"\x00\x06\x26\x01\x80\x00", // ELFLAGS
       b"\x00\x08\x2f\x03\x00\x12\x34\x56", // PLEX
       b"\x00\x06\x0d\x02\x00\x07", // LAYER 7
       b"\x00\x06\x0e\x02\x00\x02", // DATATYPE 2
       b"\x00\x2c\x10\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00", // XY
       b"\x00\x06\x2b\x02\x00\x07", // PROPATTR 7
       b"\x00\x08\x2c\x06old\x00", // PROPVALUE to rewrite
       b"\x00\x06\x2b\x02\x00\x09", // unrelated PROPATTR 9
       b"\x00\x08\x2c\x06keep", // unrelated PROPVALUE
       b"\x00\x0c\x7f\x05\x00\x00\x00\x00\x00\x00\x00\x01", // opaque extension word
       b"\x00\x0a\x7f\x06opaque", // repeated extension kind, different payload
       b"\x00\x04\x11\x00", // ENDEL
       b"\x00\x04\x07\x00", // ENDSTR
       b"\x00\x04\x04\x00", // ENDLIB
    ] {
    out.write_bytes(record)
  }
  out.write_bytes(Bytes::make(32, 0)) // physical padding belongs to this input
  out.to_bytes()
}

///|
fn main {
  let original = @gdsii.GdsLibrary::parse(original_file()).unwrap()
  let records = original.records()
  let mut changed = 0
  for i in 1..<records.length() {
    let previous = records[i - 1]
    let current = records[i]
    if previous.kind == 43 && previous.data == b"\x00\x07" && current.kind == 44 {
      records[i] = {
        offset: current.offset,
        kind: current.kind,
        data_type: current.data_type,
        data: b"route-A\x00",
      }
      changed += 1
    }
  }
  let rewritten = @gdsii.GdsLibrary::from_records(records).unwrap()
  // A well-framed stream with an orphan PROPVALUE must still be rejected.
  let invalid : Array[@gdsii.GdsRecord] = []
  for record in rewritten.records() {
    if record.kind != 43 || record.data != b"\x00\x07" {
      invalid.push(record)
    }
  }
  let rejected : Json = match @gdsii.GdsLibrary::from_records(invalid) {
    Err(error) => { "error": error.to_json() }
    Ok(_) => { "unexpected_success": true }
  }
  let result : Json = {
    "pair": {
      "schema": "gdsii-author-v1",
      // Read the source after both attempts to expose accidental alias mutation.
      "before": {
        "bytes": [ for byte in original.to_bytes() => byte.to_int() ].to_json(),
      },
      "after": {
        "bytes": [ for byte in rewritten.to_bytes() => byte.to_int() ].to_json(),
      },
    },
    "changed_properties": changed.to_json(),
    "next_property_offset": rewritten.records()[14].offset.to_json(),
    "rejected": rejected,
  }
  println(result.stringify())
}
