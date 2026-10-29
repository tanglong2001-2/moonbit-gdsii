///|
fn run_rectangle_area(request : Json) -> Json {
  guard request
    is {
      "hex": String(hex),
      "cell": String(cell),
      "layer": Number(layer, ..),
      "datatype": Number(datatype, ..),
      ..
    } else {
    return { "error": { "stage": "request", "code": "INVALID_AREA_QUERY" } }
  }
  for value in [layer, datatype] {
    if value.is_nan() ||
      value.is_inf() ||
      value < 0.0 ||
      value > 2147483647.0 ||
      value != value.trunc() {
      return { "error": { "stage": "request", "code": "INVALID_AREA_QUERY" } }
    }
  }
  let budget = match read_expansion_budget(request) {
    Ok(value) => value
    Err(detail) =>
      return {
        "error": {
          "stage": "request",
          "code": "INVALID_AREA_QUERY",
          "detail": detail,
        },
      }
  }
  let source = match library_from_hex(hex) {
    Ok(source) => source
    Err(detail) =>
      return {
        "error": {
          "stage": "source",
          "code": "GDS_PARSE_ERROR",
          "detail": detail,
        },
      }
  }
  let flat = match source.flatten_cell(cell, budget~) {
    Ok(flat) => flat
    Err(detail) =>
      return {
        "error": {
          "stage": "query",
          "code": "AREA_QUERY_ERROR",
          "detail": detail.to_json(),
        },
      }
  }
  let selection = flat.rectangles(layer.to_int(), datatype.to_int())
  let area = match @gdsii.rectangle_union_area(selection.rects) {
    Ok(area) => area
    Err(detail) =>
      return {
        "error": {
          "stage": "query",
          "code": "AREA_QUERY_ERROR",
          "detail": detail.to_json(),
        },
      }
  }
  let status = if !selection.warnings.is_empty() {
    "IncompleteGeometry"
  } else if selection.rects.is_empty() {
    "EmptySelection"
  } else {
    "Complete"
  }
  {
    "measurement": {
      "cell": cell,
      "layer": layer.to_int(),
      "datatype": datatype.to_int(),
      "status": status,
      "area_dbu2": area.to_string(),
      "checked_rectangles": selection.rects.length(),
      "selected_shapes": selection.rects.length() + selection.warnings.length(),
      "rectangles": selection.rects.to_json(),
      "skipped": selection.warnings.to_json(),
    },
  }
}
