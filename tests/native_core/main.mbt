///|
// Public-API numeric consumer for direct native execution, without host FFI.
fn encoded(value : Double) -> Json {
  match @gdsii.Real8Raw::from_f64(value) {
    Ok(raw) => { "bytes": [ for b in raw.to_bytes() => b.to_int() ].to_json() }
    Err(error) => { "error": error.to_json() }
  }
}

///|
fn main {
  let real8 : Array[Json] = []
  for
    bytes in [
      b"\x41\x80\x00\x00\x00\x00\x00\x04", b"\xc1\x80\x00\x00\x00\x00\x00\x04", b"\x00\x00\x00\x00\x00\x00\x00\x01",
    ] {
    let raw = @gdsii.Real8Raw::from_bytes(bytes).unwrap()
    real8.push({
      "raw": [ for b in raw.to_bytes() => b.to_int() ].to_json(),
      "value": raw.to_f64().to_json(),
      "reencoded": encoded(raw.to_f64()),
    })
  }
  let quantized : Array[Json] = []
  for
    value in [
      0.49999999999999994, -0.49999999999999994, 0.5, -0.5, 2147483647.5, -2147483648.5,
    ] {
    quantized.push(
      match @gdsii.quantize_dbu(value) {
        Ok(dbu) => { "dbu": dbu.to_json() }
        Err(error) => { "error": error.to_json() }
      },
    )
  }
  let invalid_raw : Json = match @gdsii.Real8Raw::from_bytes(b"bad") {
    Err(error) => { "error": error.to_json() }
    Ok(_) => { "unexpected_success": true }
  }
  let response : Json = {
    "real8": real8.to_json(),
    "quantized": quantized.to_json(),
    "invalid_raw": invalid_raw,
  }
  println(response.stringify())
}
