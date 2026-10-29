///|
fn definition_diff_hex(before : String, after : String) -> Json {
  let left = match library_from_hex(before) {
    Ok(lib) => lib
    Err(error) =>
      return {
        "error": {
          "stage": "before",
          "code": "GDS_PARSE_ERROR",
          "detail": error,
        },
      }
  }
  let right = match library_from_hex(after) {
    Ok(lib) => lib
    Err(error) =>
      return {
        "error": {
          "stage": "after",
          "code": "GDS_PARSE_ERROR",
          "detail": error,
        },
      }
  }
  { "definition_diff": left.definition_diff(right).to_json() }
}
