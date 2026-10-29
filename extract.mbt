///|
/// Export a selected definition and its known SREF/AREF dependency closure.
/// Complete raw cell blocks and non-cell library records retain source order.
/// Missing reachable targets fail; closed cycles remain valid, unexpanded data.
/// Offsets are recomputed and physical tail padding is omitted, as from_records.
/// Unknown extensions are preserved without inferring their dependency semantics.
pub fn GdsLibrary::extract_cell(
  self : GdsLibrary,
  cell : String,
) -> Result[GdsLibrary, GdsError] {
  let scope = match self.hierarchy(cell) {
    Ok(scope) => scope
    Err(error) => return Err(error)
  }
  if !scope.missing_references.is_empty() {
    return Err(MissingCell(scope.missing_references[0].target))
  }
  let keep : Map[String, Bool] = Map([])
  for name in scope.reachable_cells {
    keep[name] = true
  }
  let records = []
  let mut start = -1
  let mut definition = 0
  // Validated library framing pairs these blocks with self.cells in file order.
  // In particular, STRNAME need not immediately follow BGNSTR.
  for index, record in self.records {
    match record.kind {
      5 => start = index
      7 => {
        if keep.contains(self.cells[definition].name) {
          for i in start..<(index + 1) {
            records.push(self.records[i])
          }
        }
        definition += 1
        start = -1
      }
      _ => if start < 0 { records.push(record) }
    }
  }
  GdsLibrary::from_records(records)
}
