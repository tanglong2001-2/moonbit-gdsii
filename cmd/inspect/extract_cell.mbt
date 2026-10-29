///|
fn extract_hex(hex : String, cell : String) -> Json {
  let source = match library_from_hex(hex) {
    Ok(source) => source
    Err(error) => return { "error": { "stage": "parse", "detail": error } }
  }
  let extracted = match source.extract_cell(cell) {
    Ok(extracted) => extracted
    Err(error) =>
      return { "error": { "stage": "query", "detail": error.to_json() } }
  }
  {
    "extraction": {
      "cell": cell,
      "kept_cells": [
        for entry in extracted.catalog().cells => entry.name
      ].to_json(),
      "bytes": [ for byte in extracted.to_bytes() => byte.to_int() ].to_json(),
    },
  }
}
