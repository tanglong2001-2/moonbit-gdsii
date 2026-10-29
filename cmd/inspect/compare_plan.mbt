///|
// Reuse the existing strict plan and finding-diff contracts on two snapshots.
fn run_compare_plan(
  before_hex : String,
  after_hex : String,
  value : Json,
) -> Json {
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
  let before_lib = match library_from_hex(before_hex) {
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
  let after_lib = match library_from_hex(after_hex) {
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
  let mut no_new_issues = 0
  let mut new_issues = 0
  let mut incomplete = 0
  let mut errors = 0
  let unchecked : Array[String] = []
  let results : Array[Json] = []
  for profile in plan.profiles {
    // Always evaluate both sides: one hierarchy failure must not hide the other.
    let before = before_lib.preflight_cell(
      plan.cell,
      profile.layer,
      profile.datatype,
      profile.min_width,
      profile.min_spacing,
      budget=plan.budget,
    )
    let after = after_lib.preflight_cell(
      plan.cell,
      profile.layer,
      profile.datatype,
      profile.min_width,
      profile.min_spacing,
      budget=plan.budget,
    )
    let left : Json = match before {
      Ok(report) => { "preflight": report.to_json() }
      Err(error) => { "error": error.to_json() }
    }
    let right : Json = match after {
      Ok(report) => { "preflight": report.to_json() }
      Err(error) => { "error": error.to_json() }
    }
    let result : Json = match (before, after) {
      (Ok(before), Ok(after)) =>
        match before.diff(after) {
          Ok(comparison) => {
            match comparison.status {
              @gdsii.NoNewIssues => no_new_issues += 1
              @gdsii.NewIssuesFound => new_issues += 1
              @gdsii.IncompleteComparison => {
                incomplete += 1
                unchecked.push(profile.id)
              }
            }
            {
              "id": profile.id,
              "before": left,
              "after": right,
              "comparison": comparison.to_json(),
            }
          }
          Err(error) => {
            errors += 1
            unchecked.push(profile.id)
            {
              "id": profile.id,
              "before": left,
              "after": right,
              "error": { "side": "comparison", "detail": error.to_json() },
            }
          }
        }
      _ => {
        errors += 1
        unchecked.push(profile.id)
        { "id": profile.id, "before": left, "after": right }
      }
    }
    results.push(result)
  }
  let status = if errors > 0 {
    "ErrorsFound"
  } else if !unchecked.is_empty() {
    "Incomplete"
  } else if new_issues > 0 {
    "NewIssuesFound"
  } else {
    "NoNewIssues"
  }
  {
    "comparison_review": {
      "cell": plan.cell,
      "budget": plan.budget,
      "profiles": plan.profiles.to_json(),
      "status": status,
      "counts": {
        "no_new_issues": no_new_issues,
        "new_issues": new_issues,
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
