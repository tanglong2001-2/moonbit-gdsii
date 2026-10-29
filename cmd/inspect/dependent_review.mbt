///|
// One parsed snapshot, one whole-cell report per known dependent definition.
fn run_dependent_review(request : Json) -> Json {
  guard request
    is {
      "hex": String(hex),
      "cell": String(target),
      "layer": Number(layer, ..),
      "datatype": Number(datatype, ..),
      "width": Number(width, ..),
      "spacing": Number(spacing, ..),
      ..
    } else {
    return { "error": "expected hex, cell, layer, datatype, width, spacing" }
  }
  for value in [layer, datatype, width, spacing] {
    if value.is_nan() ||
      value.is_inf() ||
      value < 0.0 ||
      value > 2147483647.0 ||
      value != value.trunc() {
      return {
        "error": "selectors and thresholds must be nonnegative INT32 integers",
      }
    }
  }
  let budget = match read_expansion_budget(request) {
    Ok(value) => value
    Err(error) => return { "error": error }
  }
  let lib = match library_from_hex(hex) {
    Ok(lib) => lib
    Err(error) => return { "error": error }
  }
  let dependency = lib.reference_impact(target)
  let counts = TopBatchCounts::{
    passed: 0,
    failed: 0,
    incomplete: 0,
    errors: 0,
    unchecked_cells: [],
  }
  let results : Array[Json] = []
  for cell in dependency.cells {
    match
      lib.preflight_cell(
        cell.name,
        layer.to_int(),
        datatype.to_int(),
        width.to_int(),
        spacing.to_int(),
        budget~,
      ) {
      Ok(report) => {
        counts.preflight(report)
        results.push({ "cell": cell.name, "preflight": report.to_json() })
      }
      Err(error) => {
        counts.errors += 1
        counts.unchecked_cells.push(cell.name)
        results.push({ "cell": cell.name, "error": error.to_json() })
      }
    }
  }
  // Coverage takes precedence over findings; an empty queue is not a pass.
  let status = if counts.errors > 0 {
    "ErrorsFound"
  } else if results.is_empty() || !counts.unchecked_cells.is_empty() {
    "Incomplete"
  } else if counts.failed > 0 {
    "IssuesFound"
  } else {
    "Passed"
  }
  {
    "dependent_review": {
      "dependency": dependency.to_json(),
      "profile": {
        "layer": layer,
        "datatype": datatype,
        "min_width": width,
        "min_spacing": spacing,
        "budget": budget,
      },
      "status": status,
      "counts": {
        "passed": counts.passed,
        "failed": counts.failed,
        "incomplete": counts.incomplete,
        "errors": counts.errors,
      },
      "coverage": {
        "complete": !results.is_empty() && counts.unchecked_cells.is_empty(),
        "unchecked_cells": counts.unchecked_cells.to_json(),
      },
      "results": results.to_json(),
    },
  }
}
