///|
fn rename_hex(hex : String, old_name : String, new_name : String) -> Json {
  let source = match library_from_hex(hex) {
    Ok(source) => source
    Err(error) => return { "error": { "stage": "parse", "detail": error } }
  }
  let renamed = match source.rename_cell(old_name, new_name) {
    Ok(renamed) => renamed
    Err(error) =>
      return { "error": { "stage": "query", "detail": error.to_json() } }
  }
  let mut updated_references = 0
  if old_name != new_name {
    for cell in source.catalog().cells {
      for reference in cell.references {
        if reference.target == old_name {
          updated_references += 1
        }
      }
    }
  }
  {
    "renaming": {
      "old_name": old_name,
      "new_name": new_name,
      "updated_references": updated_references,
      "cells": [ for entry in renamed.catalog().cells => entry.name ].to_json(),
      "bytes": [ for byte in renamed.to_bytes() => byte.to_int() ].to_json(),
    },
  }
}
