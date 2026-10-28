///|
struct TopBatchCounts {
  mut passed : Int
  mut failed : Int
  mut incomplete : Int
  mut errors : Int
  unchecked_cells : Array[String]
}

///|
fn TopBatchCounts::preflight(
  self : TopBatchCounts,
  report : @gdsii.PreflightReport,
) -> Unit {
  match report.status {
    @gdsii.RectanglesClear => self.passed += 1
    @gdsii.ViolationsFound => self.failed += 1
    @gdsii.IncompleteGeometry | @gdsii.EmptySelection => self.incomplete += 1
  }
  if report.checked_rectangles <= 0 || !report.skipped.is_empty() {
    self.unchecked_cells.push(report.cell)
  }
}

///|
fn TopBatchCounts::comparison(
  self : TopBatchCounts,
  report : @gdsii.PreflightDiff,
) -> Unit {
  match report.status {
    @gdsii.NoNewIssues => self.passed += 1
    @gdsii.NewIssuesFound => self.failed += 1
    @gdsii.IncompleteComparison => self.incomplete += 1
  }
  if report.before_checked_rectangles <= 0 ||
    report.after_checked_rectangles <= 0 ||
    !report.before_skipped.is_empty() ||
    !report.after_skipped.is_empty() {
    self.unchecked_cells.push(report.cell)
  }
}

///|
fn TopBatchCounts::response(
  self : TopBatchCounts,
  compare : Bool,
  before_tops : Array[String],
  after_tops : Array[String],
  results : Array[Json],
) -> Json {
  let status = if self.errors > 0 {
    "ErrorsFound"
  } else if self.incomplete > 0 || results.is_empty() {
    "Incomplete"
  } else if self.failed > 0 {
    "IssuesFound"
  } else {
    "Passed"
  }
  let counts : Json = {
    "passed": self.passed,
    "failed": self.failed,
    "incomplete": self.incomplete,
    "errors": self.errors,
  }
  let coverage : Json = {
    "complete": !results.is_empty() && self.unchecked_cells.is_empty(),
    "unchecked_cells": self.unchecked_cells.to_json(),
  }
  if compare {
    {
      "batch": {
        "mode": "compare-tops",
        "status": status,
        "before_top_cells": before_tops.to_json(),
        "after_top_cells": after_tops.to_json(),
        "results": results.to_json(),
        "counts": counts,
        "coverage": coverage,
      },
    }
  } else {
    {
      "batch": {
        "mode": "preflight-tops",
        "status": status,
        "top_cells": before_tops.to_json(),
        "results": results.to_json(),
        "counts": counts,
        "coverage": coverage,
      },
    }
  }
}

///|
fn run_top_batch(request : Json, compare : Bool) -> Json {
  guard request
    is {
      "hex": String(hex),
      "layer": Number(layer, ..),
      "datatype": Number(datatype, ..),
      "width": Number(width, ..),
      "spacing": Number(spacing, ..),
      ..
    } else {
    return { "error": "expected hex, layer, datatype, width, spacing" }
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
  let before_lib = match library_from_hex(hex) {
    Ok(lib) => lib
    Err(error) =>
      return if compare {
        { "error": { "side": "before", "detail": error } }
      } else {
        { "error": error }
      }
  }
  let before_tops = before_lib.catalog().top_cells
  let counts = TopBatchCounts::{
    passed: 0,
    failed: 0,
    incomplete: 0,
    errors: 0,
    unchecked_cells: [],
  }
  let results : Array[Json] = []
  if !compare {
    for cell in before_tops {
      let result : Json = match
        before_lib.preflight_cell(
          cell,
          layer.to_int(),
          datatype.to_int(),
          width.to_int(),
          spacing.to_int(),
          budget~,
        ) {
        Ok(report) => {
          counts.preflight(report)
          { "cell": cell, "preflight": report.to_json() }
        }
        Err(error) => {
          counts.errors += 1
          counts.unchecked_cells.push(cell)
          { "cell": cell, "error": error.to_json() }
        }
      }
      results.push(result)
    }
    return counts.response(false, before_tops, [], results)
  }
  guard request is { "after_hex": String(after_hex), .. } else {
    return { "error": "compare-tops requires after_hex" }
  }
  let after_lib = match library_from_hex(after_hex) {
    Ok(lib) => lib
    Err(error) => return { "error": { "side": "after", "detail": error } }
  }
  let after_tops = after_lib.catalog().top_cells
  let before_names : Map[String, Bool] = Map([])
  let after_names : Map[String, Bool] = Map([])
  let cells = before_tops.copy()
  for cell in before_tops {
    before_names[cell] = true
  }
  for cell in after_tops {
    after_names[cell] = true
    if !before_names.contains(cell) {
      cells.push(cell)
    }
  }
  for cell in cells {
    let difference : Result[@gdsii.PreflightDiff, Json] = match
      before_lib.preflight_cell(
        cell,
        layer.to_int(),
        datatype.to_int(),
        width.to_int(),
        spacing.to_int(),
        budget~,
      ) {
      Err(error) => Err({ "side": "before", "detail": error.to_json() })
      Ok(before) =>
        match
          after_lib.preflight_cell(
            cell,
            layer.to_int(),
            datatype.to_int(),
            width.to_int(),
            spacing.to_int(),
            budget~,
          ) {
          Err(error) => Err({ "side": "after", "detail": error.to_json() })
          Ok(after) =>
            match before.diff(after) {
              Ok(report) => Ok(report)
              Err(error) =>
                Err({ "side": "comparison", "detail": error.to_json() })
            }
        }
    }
    let result : Json = match difference {
      Ok(report) => {
        counts.comparison(report)
        {
          "cell": cell,
          "before_top": before_names.contains(cell),
          "after_top": after_names.contains(cell),
          "comparison": report.to_json(),
        }
      }
      Err(error) => {
        counts.errors += 1
        counts.unchecked_cells.push(cell)
        {
          "cell": cell,
          "before_top": before_names.contains(cell),
          "after_top": after_names.contains(cell),
          "error": error,
        }
      }
    }
    results.push(result)
  }
  counts.response(true, before_tops, after_tops, results)
}
