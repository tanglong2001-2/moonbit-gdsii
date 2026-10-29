///|
extern "js" fn request_text() -> String = "() => process.argv[2] || require('node:fs').readFileSync(0,'utf8')"

///|
fn read_expansion_budget(request : Json) -> Result[Int, Json] {
  match request {
    { "budget": Number(value, ..), .. } =>
      if value.is_nan() ||
        value.is_inf() ||
        value <= 0.0 ||
        value > 2147483647.0 ||
        value != value.trunc() {
        Err("budget must be a positive INT32 integer")
      } else {
        Ok(value.to_int())
      }
    { "budget": _, .. } => Err("budget must be a positive INT32 integer")
    _ => Ok(100000)
  }
}

///|
fn nibble(c : UInt16) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - 48
  } else if c >= 'a' && c <= 'f' {
    c.to_int() - 87
  } else if c >= 'A' && c <= 'F' {
    c.to_int() - 55
  } else {
    -1
  }
}

///|
fn library_from_hex(hex : String) -> Result[@gdsii.GdsLibrary, Json] {
  if hex.length() % 2 != 0 {
    return Err("odd hex length")
  }
  let buffer = @buffer.Buffer()
  for i in 0..<(hex.length() / 2) {
    let hi = nibble(hex[i * 2])
    let lo = nibble(hex[i * 2 + 1])
    if hi < 0 || lo < 0 {
      return Err("invalid hex digit")
    }
    buffer.write_byte((hi * 16 + lo).to_byte())
  }
  match @gdsii.GdsLibrary::parse(buffer.to_bytes()) {
    Ok(lib) => Ok(lib)
    Err(e) => Err(e.to_json())
  }
}

///|
fn compare_hex(
  before_hex : String,
  after_hex : String,
  cell : String,
  layer : Int,
  datatype : Int,
  width : Int,
  spacing : Int,
  budget : Int,
) -> Json {
  let before_lib = match library_from_hex(before_hex) {
    Ok(lib) => lib
    Err(error) => return { "error": { "side": "before", "detail": error } }
  }
  let after_lib = match library_from_hex(after_hex) {
    Ok(lib) => lib
    Err(error) => return { "error": { "side": "after", "detail": error } }
  }
  let before = match
    before_lib.preflight_cell(cell, layer, datatype, width, spacing, budget~) {
    Ok(report) => report
    Err(error) =>
      return { "error": { "side": "before", "detail": error.to_json() } }
  }
  let after = match
    after_lib.preflight_cell(cell, layer, datatype, width, spacing, budget~) {
    Ok(report) => report
    Err(error) =>
      return { "error": { "side": "after", "detail": error.to_json() } }
  }
  match before.diff(after) {
    Ok(difference) => { "comparison": difference.to_json() }
    Err(error) =>
      { "error": { "side": "comparison", "detail": error.to_json() } }
  }
}

///|
fn run(request : Json) -> Json {
  if request is { "mode": String("rename-cell"), .. } {
    guard request
      is {
        "hex": String(hex),
        "old_name": String(old_name),
        "new_name": String(new_name),
        ..
      } else {
      return { "error": "rename-cell requires hex, old_name and new_name" }
    }
    return rename_hex(hex, old_name, new_name)
  }
  if request is { "mode": String("extract-cell"), .. } {
    guard request is { "hex": String(hex), "cell": String(cell), .. } else {
      return { "error": "extract-cell requires hex and cell" }
    }
    return extract_hex(hex, cell)
  }
  if request is { "mode": String("review-plan"), .. } {
    guard request is { "hex": String(hex), "plan": plan, .. } else {
      return { "error": "review-plan requires hex and plan" }
    }
    return run_review_plan(hex, plan)
  }
  if request is { "mode": String("preflight-tops"), .. } {
    return run_top_batch(request, false)
  }
  if request is { "mode": String("compare-tops"), .. } {
    return run_top_batch(request, true)
  }
  if request is { "mode": String("catalog"), "hex": String(hex), .. } {
    return match library_from_hex(hex) {
      Ok(lib) => { "catalog": lib.catalog().to_json() }
      Err(error) => { "error": error }
    }
  }
  if request
    is {
      "mode": String("hierarchy"),
      "hex": String(hex),
      "cell": String(cell),
      ..
    } {
    let lib = match library_from_hex(hex) {
      Ok(lib) => lib
      Err(error) => return { "error": error }
    }
    return match lib.hierarchy(cell) {
      Ok(report) => { "hierarchy": report.to_json() }
      Err(error) => { "error": error.to_json() }
    }
  }
  guard request
    is {
      "hex": String(hex),
      "cell": String(cell),
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
  if request is { "mode": String("compare"), .. } {
    guard request is { "after_hex": String(after_hex), .. } else {
      return { "error": "compare requires after_hex" }
    }
    return compare_hex(
      hex,
      after_hex,
      cell,
      layer.to_int(),
      datatype.to_int(),
      width.to_int(),
      spacing.to_int(),
      budget,
    )
  }
  let lib = match library_from_hex(hex) {
    Ok(lib) => lib
    Err(error) => return { "error": error }
  }
  if request is { "mode": String("preflight"), .. } {
    return match
      lib.preflight_cell(
        cell,
        layer.to_int(),
        datatype.to_int(),
        width.to_int(),
        spacing.to_int(),
        budget~,
      ) {
      Ok(report) => { "preflight": report.to_json() }
      Err(error) => { "error": error.to_json() }
    }
  }
  let flat = match lib.flatten_cell(cell, budget~) {
    Ok(flat) => flat
    Err(e) => return { "error": e.to_json() }
  }
  let geometry = flat.rectangles(layer.to_int(), datatype.to_int())
  let report = match
    @gdsii.check_manhattan_drc(geometry.rects, width.to_int(), spacing.to_int()) {
    Ok(report) => report
    Err(e) => return { "error": e.to_json() }
  }
  {
    "library": lib.name().to_json(),
    "flattened": flat.to_json(),
    "selection": geometry.to_json(),
    "drc": report.to_json(),
  }
}

///|
fn main {
  let response = run(@json.parse(request_text())) catch {
    _ => { "error": "invalid JSON request" }
  }
  println(response.stringify())
}
