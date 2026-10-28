///|
/// NoNewIssues is a regression result, not a claim that retained issues are clear.
pub(all) enum PreflightDiffStatus {
  NoNewIssues
  NewIssuesFound
  IncompleteComparison
} derive(Debug, Eq, ToJson)

///|
/// Exact world-rectangle finding multiset delta on an identical report profile.
/// Removed means no longer reported at that geometry, not a certified repair.
pub(all) struct PreflightDiff {
  cell : String
  layer : Int
  datatype : Int
  min_width : Int
  min_spacing : Int
  dbu_in_meters : Double
  status : PreflightDiffStatus
  before_status : PreflightStatus
  after_status : PreflightStatus
  before_checked_rectangles : Int
  after_checked_rectangles : Int
  before_skipped : Array[GeometryWarning]
  after_skipped : Array[GeometryWarning]
  introduced : Array[PreflightIssue]
  removed : Array[PreflightIssue]
  retained : Int
} derive(Debug, ToJson)

///|
fn geometry_key(rect : Rect) -> String {
  "\{rect.min_x},\{rect.min_y},\{rect.max_x},\{rect.max_y}"
}

///|
fn geometry_less(a : Rect, b : Rect) -> Bool {
  if a.min_x != b.min_x {
    a.min_x < b.min_x
  } else if a.min_y != b.min_y {
    a.min_y < b.min_y
  } else if a.max_x != b.max_x {
    a.max_x < b.max_x
  } else {
    a.max_y < b.max_y
  }
}

///|
fn finding_key(
  issue : PreflightIssue,
  report : PreflightReport,
) -> Result[String, GdsError] {
  let required = match issue.rule {
    Width => report.min_width
    Spacing => report.min_spacing
  }
  if issue.required != required {
    return Err(InvalidGeometry("issue threshold differs from report profile"))
  }
  match issue.rule {
    Width => {
      if issue.rectangles.length() != 1 {
        return Err(InvalidGeometry("width issue requires one rectangle"))
      }
      Ok("W:\{geometry_key(issue.rectangles[0])}")
    }
    Spacing => {
      if issue.rectangles.length() != 2 {
        return Err(InvalidGeometry("spacing issue requires two rectangles"))
      }
      let a = issue.rectangles[0]
      let b = issue.rectangles[1]
      let (first, second) = if geometry_less(b, a) { (b, a) } else { (a, b) }
      Ok("S:\{geometry_key(first)}|\{geometry_key(second)}")
    }
  }
}

///|
fn copy_finding(issue : PreflightIssue) -> PreflightIssue {
  {
    rule: issue.rule,
    rectangles: issue.rectangles.copy(),
    required: issue.required,
    measured: issue.measured,
    shortfall: issue.shortfall,
  }
}

///|
/// Compare reported findings as a geometry/rule MULTISET. Source paths and rounded
/// diagnostics are not identity. Moving/reshaping a finding removes/introduces it;
/// no object tracking or geometry equivalence is inferred. Profiles must match.
/// Arrays are fresh; empty/skipped checked scope yields IncompleteComparison.
pub fn PreflightReport::diff(
  self : PreflightReport,
  after : PreflightReport,
) -> Result[PreflightDiff, GdsError] {
  if self.cell != after.cell ||
    self.layer != after.layer ||
    self.datatype != after.datatype ||
    self.min_width != after.min_width ||
    self.min_spacing != after.min_spacing ||
    self.dbu_in_meters != after.dbu_in_meters {
    return Err(InvalidGeometry("preflight report profiles differ"))
  }
  let before_keys = []
  let after_keys = []
  let remaining_before : Map[String, Int] = Map([])
  let remaining_after : Map[String, Int] = Map([])
  for issue in self.issues {
    let key = match finding_key(issue, self) {
      Ok(key) => key
      Err(error) => return Err(error)
    }
    before_keys.push(key)
    remaining_before[key] = match remaining_before.get(key) {
      Some(count) => count + 1
      None => 1
    }
  }
  for issue in after.issues {
    let key = match finding_key(issue, after) {
      Ok(key) => key
      Err(error) => return Err(error)
    }
    after_keys.push(key)
    remaining_after[key] = match remaining_after.get(key) {
      Some(count) => count + 1
      None => 1
    }
  }
  let introduced = []
  let removed = []
  let mut retained = 0
  for i, key in after_keys {
    let count = remaining_before.get(key).unwrap_or(0)
    if count > 0 {
      remaining_before[key] = count - 1
      retained += 1
    } else {
      introduced.push(copy_finding(after.issues[i]))
    }
  }
  for i, key in before_keys {
    let count = remaining_after.get(key).unwrap_or(0)
    if count > 0 {
      remaining_after[key] = count - 1
    } else {
      removed.push(copy_finding(self.issues[i]))
    }
  }
  let status : PreflightDiffStatus = if !self.skipped.is_empty() ||
    !after.skipped.is_empty() ||
    self.checked_rectangles <= 0 ||
    after.checked_rectangles <= 0 {
    IncompleteComparison
  } else if !introduced.is_empty() {
    NewIssuesFound
  } else {
    NoNewIssues
  }
  Ok({
    cell: self.cell,
    layer: self.layer,
    datatype: self.datatype,
    min_width: self.min_width,
    min_spacing: self.min_spacing,
    dbu_in_meters: self.dbu_in_meters,
    status,
    before_status: self.status,
    after_status: after.status,
    before_checked_rectangles: self.checked_rectangles,
    after_checked_rectangles: after.checked_rectangles,
    before_skipped: self.skipped.copy(),
    after_skipped: after.skipped.copy(),
    introduced,
    removed,
    retained,
  })
}
