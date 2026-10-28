///|
pub(all) enum PreflightRule {
  Width
  Spacing
} derive(Debug, Eq, ToJson)

///|
/// RectanglesClear applies only to the selected raw rectangle rule profile.
pub(all) enum PreflightStatus {
  RectanglesClear
  ViolationsFound
  IncompleteGeometry
  EmptySelection
} derive(Debug, Eq, ToJson)

///|
/// Source-located issue in output DBU. Measured/shortfall are approximate Double
/// diagnostics; classification uses the existing exact rectangle predicates.
/// Shortfall is a rule deficit, not a safe edit displacement or resize plan.
pub(all) struct PreflightIssue {
  rule : PreflightRule
  rectangles : Array[Rect]
  required : Int
  measured : Double
  shortfall : Double
} derive(Debug, ToJson)

///|
pub(all) struct PreflightReport {
  cell : String
  layer : Int
  datatype : Int
  min_width : Int
  min_spacing : Int
  dbu_in_meters : Double
  status : PreflightStatus
  selected_shapes : Int
  checked_rectangles : Int
  skipped : Array[GeometryWarning]
  issues : Array[PreflightIssue]
  candidates : Int64
  index_visits : Int64
} derive(Debug, ToJson)

///|
fn spacing_shortfall(
  a : Rect,
  b : Rect,
  required : Int,
  measured : Double,
) -> Double {
  let dx = (a.min_x.to_int64() - b.max_x.to_int64())
    .max(b.min_x.to_int64() - a.max_x.to_int64())
    .max(0L)
  let dy = (a.min_y.to_int64() - b.max_y.to_int64())
    .max(b.min_y.to_int64() - a.max_y.to_int64())
    .max(0L)
  let threshold = required.to_int64()
  // Called only for an established spacing violation: dx,dy < threshold,
  // and threshold^2 - dx^2 - dy^2 is strictly positive. Keep subtraction order.
  let squared_deficit = threshold * threshold - dx * dx - dy * dy
  squared_deficit.to_double() / (required.to_double() + measured)
}

///|
/// Flatten one cell, select (layer,datatype) and report located raw box findings.
/// Empty/skipped geometry cannot become a clear result. Numeric/graph/budget
/// errors propagate; this report neither edits geometry nor certifies signoff.
pub fn GdsLibrary::preflight_cell(
  self : GdsLibrary,
  cell : String,
  layer : Int,
  datatype : Int,
  min_width : Int,
  min_spacing : Int,
  budget? : Int = 100000,
) -> Result[PreflightReport, GdsError] {
  if layer < 0 || datatype < 0 {
    return Err(InvalidGeometry("negative layer/datatype selector"))
  }
  if min_width < 0 || min_spacing < 0 {
    return Err(InvalidGeometry("negative DRC threshold"))
  }
  let flat = match self.flatten_cell(cell, budget~) {
    Ok(flat) => flat
    Err(error) => return Err(error)
  }
  let selection = flat.rectangles(layer, datatype)
  let drc = match check_manhattan_drc(selection.rects, min_width, min_spacing) {
    Ok(drc) => drc
    Err(error) => return Err(error)
  }
  let issues : Array[PreflightIssue] = []
  for violation in drc.violations {
    match violation {
      MinimumWidth(index, measured) =>
        issues.push({
          rule: Width,
          rectangles: [selection.rects[index]],
          required: min_width,
          measured: measured.to_double(),
          shortfall: min_width.to_double() - measured.to_double(),
        })
      MinimumSpacing(first, second, measured) => {
        let a = selection.rects[first]
        let b = selection.rects[second]
        issues.push({
          rule: Spacing,
          rectangles: [a, b],
          required: min_spacing,
          measured,
          shortfall: spacing_shortfall(a, b, min_spacing, measured),
        })
      }
    }
  }
  let status : PreflightStatus = if !issues.is_empty() {
    ViolationsFound
  } else if !selection.warnings.is_empty() {
    IncompleteGeometry
  } else if selection.rects.is_empty() {
    EmptySelection
  } else {
    RectanglesClear
  }
  Ok({
    cell,
    layer,
    datatype,
    min_width,
    min_spacing,
    dbu_in_meters: self.units_meters.to_f64(),
    status,
    selected_shapes: selection.rects.length() + selection.warnings.length(),
    checked_rectangles: drc.rectangles_checked,
    skipped: selection.warnings,
    issues,
    candidates: drc.candidates,
    index_visits: drc.index_visits,
  })
}
