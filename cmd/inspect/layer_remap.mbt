///|
fn remap_layers_hex(hex : String, values : Json) -> Json {
  guard values is Array(entries) else {
    return { "error": { "stage": "map", "code": "INVALID_LAYER_REMAP" } }
  }
  let mappings : Array[@gdsii.LayerRemap] = []
  for entry in entries {
    guard entry
      is {
        "from_layer": Number(from_layer, ..),
        "from_type": Number(from_type, ..),
        "to_layer": Number(to_layer, ..),
        "to_type": Number(to_type, ..),
        ..
      } else {
      return { "error": { "stage": "map", "code": "INVALID_LAYER_REMAP" } }
    }
    for value in [from_layer, from_type, to_layer, to_type] {
      if value.is_nan() ||
        value.is_inf() ||
        value < 0.0 ||
        value > 65535.0 ||
        value != value.trunc() {
        return { "error": { "stage": "map", "code": "INVALID_LAYER_REMAP" } }
      }
    }
    mappings.push({
      from_layer: from_layer.to_int(),
      from_type: from_type.to_int(),
      to_layer: to_layer.to_int(),
      to_type: to_type.to_int(),
    })
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
  let output = match source.remap_layers(mappings) {
    Ok(output) => output
    Err(detail) =>
      return {
        "error": {
          "stage": "map",
          "code": "INVALID_LAYER_REMAP",
          "detail": detail.to_json(),
        },
      }
  }
  let before_cells = source.cells()
  let after_cells = output.cells()
  let mut changed_elements = 0
  for cell_index in 0..<before_cells.length() {
    for element_index, before in before_cells[cell_index].elements {
      let after = after_cells[cell_index].elements[element_index]
      if before.layer != after.layer || before.datatype != after.datatype {
        changed_elements += 1
      }
    }
  }
  {
    "remapping": {
      "changed_elements": changed_elements,
      "catalog": output.catalog().to_json(),
      "bytes": [ for byte in output.to_bytes() => byte.to_int() ].to_json(),
    },
  }
}
