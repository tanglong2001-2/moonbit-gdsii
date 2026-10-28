///|
struct ReviewProfile {
  id : String
  layer : Int
  datatype : Int
  min_width : Int
  min_spacing : Int
} derive(ToJson)

///|
struct ReviewPlan {
  cell : String
  budget : Int
  profiles : Array[ReviewProfile]
}

///|
fn review_fields_allowed(value : Json, allowed : Array[String]) -> Bool {
  guard value is Object(fields) else { return false }
  for key, _ in fields {
    if !allowed.contains(key) {
      return false
    }
  }
  true
}

///|
fn read_review_plan(value : Json) -> Result[ReviewPlan, String] {
  if !review_fields_allowed(value, ["schema", "cell", "budget", "profiles"]) {
    return Err(
      "plan must be an object containing only schema, cell, budget and profiles",
    )
  }
  guard value
    is {
      "schema": String("gdsii-rectangle-review-plan-v1"),
      "cell": String(cell),
      "profiles": Array(values),
      ..
    } else {
    return Err("expected gdsii-rectangle-review-plan-v1, cell and profiles")
  }
  if cell.is_empty() || values.is_empty() {
    return Err("cell and profiles must be nonempty")
  }
  let budget = match read_expansion_budget(value) {
    Ok(budget) => budget
    Err(_) => return Err("budget must be a positive INT32 integer")
  }
  let ids : Map[String, Bool] = Map([])
  let profiles = []
  for item in values {
    if !review_fields_allowed(item, [
        "id", "layer", "datatype", "min_width", "min_spacing",
      ]) {
      return Err(
        "profile must contain only id, layer, datatype, min_width and min_spacing",
      )
    }
    guard item
      is {
        "id": String(id),
        "layer": Number(layer, ..),
        "datatype": Number(datatype, ..),
        "min_width": Number(width, ..),
        "min_spacing": Number(spacing, ..),
        ..
      } else {
      return Err(
        "each profile requires id and four explicit numeric selectors/rules",
      )
    }
    if id.is_empty() || ids.contains(id) {
      return Err("profile ids must be nonempty and unique")
    }
    for number in [layer, datatype, width, spacing] {
      if number.is_nan() ||
        number.is_inf() ||
        number < 0.0 ||
        number > 2147483647.0 ||
        number != number.trunc() {
        return Err(
          "selectors and thresholds must be nonnegative INT32 integers",
        )
      }
    }
    ids[id] = true
    profiles.push(ReviewProfile::{
      id,
      layer: layer.to_int(),
      datatype: datatype.to_int(),
      min_width: width.to_int(),
      min_spacing: spacing.to_int(),
    })
  }
  Ok({ cell, budget, profiles, })
}

///|
fn run_review_plan(hex : String, value : Json) -> Json {
  // Validate the entire plan before parsing/evaluating any source geometry.
  let plan = match read_review_plan(value) {
    Ok(plan) => plan
    Err(message) =>
      return {
        "error": {
          "stage": "plan",
          "code": "INVALID_REVIEW_PLAN",
          "message": message,
        },
      }
  }
  let lib = match library_from_hex(hex) {
    Ok(lib) => lib
    Err(error) =>
      return {
        "error": {
          "stage": "source",
          "code": "GDS_PARSE_ERROR",
          "detail": error,
        },
      }
  }
  let mut passed = 0
  let mut failed = 0
  let mut incomplete = 0
  let mut errors = 0
  let unchecked : Array[String] = []
  let results : Array[Json] = []
  for profile in plan.profiles {
    match
      lib.preflight_cell(
        plan.cell,
        profile.layer,
        profile.datatype,
        profile.min_width,
        profile.min_spacing,
        budget=plan.budget,
      ) {
      Ok(report) => {
        match report.status {
          @gdsii.RectanglesClear => passed += 1
          @gdsii.ViolationsFound => failed += 1
          @gdsii.IncompleteGeometry | @gdsii.EmptySelection => incomplete += 1
        }
        if report.checked_rectangles <= 0 || !report.skipped.is_empty() {
          unchecked.push(profile.id)
        }
        results.push({ "id": profile.id, "preflight": report.to_json() })
      }
      Err(error) => {
        errors += 1
        unchecked.push(profile.id)
        results.push({ "id": profile.id, "error": error.to_json() })
      }
    }
  }
  // A finding can coexist with skipped geometry: coverage takes precedence.
  let status = if errors > 0 {
    "ErrorsFound"
  } else if !unchecked.is_empty() {
    "Incomplete"
  } else if failed > 0 {
    "IssuesFound"
  } else {
    "Passed"
  }
  {
    "review": {
      "cell": plan.cell,
      "budget": plan.budget,
      "profiles": plan.profiles.to_json(),
      "status": status,
      "counts": {
        "passed": passed,
        "failed": failed,
        "incomplete": incomplete,
        "errors": errors,
      },
      "coverage": {
        "complete": unchecked.is_empty(),
        "unchecked_profiles": unchecked.to_json(),
      },
      "results": results.to_json(),
    },
  }
}
