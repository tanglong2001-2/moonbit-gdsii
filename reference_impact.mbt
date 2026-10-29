///|
/// One known definition and a shortest supported reference path to the target.
/// A defined target includes itself with an empty witness. Indices are zero-based.
pub(all) struct ReferenceImpactCell {
  name : String
  is_top : Bool
  witness : Array[CatalogReference]
} derive(Debug, ToJson)

///|
/// Potential definition dependencies, not instance locations or a validity claim.
pub(all) struct ReferenceImpact {
  target : String
  target_defined : Bool
  cells : Array[ReferenceImpactCell]
} derive(Debug, ToJson)

///|
/// Find all known cells with a zero-or-more SREF/AREF path to an exact symbol.
/// Output follows source definition order. AREF is one edge; array multiplicity
/// remains metadata. Missing symbols can have known callers; an unreferenced
/// unknown symbol has no entries. Cycles terminate without geometry expansion.
/// Witnesses use the fewest reference edges. Reverse breadth-first discovery
/// visits incoming edges in source-cell/element order and retains the first tie.
/// Every returned array is fresh; editing it cannot change this library.
pub fn GdsLibrary::reference_impact(
  self : GdsLibrary,
  target : String,
) -> ReferenceImpact {
  let catalog = self.catalog()
  let incoming : Map[String, Array[CatalogReference]] = Map([])
  let names : Map[String, Bool] = Map([])
  for cell in catalog.cells {
    names[cell.name] = true
    for reference in cell.references {
      match incoming.get(reference.target) {
        Some(edges) => edges.push(reference)
        None => incoming[reference.target] = [reference]
      }
    }
  }
  let seen : Map[String, Bool] = Map([])
  let next_edge : Map[String, CatalogReference] = Map([])
  let queue = [target]
  seen[target] = true
  let mut head = 0
  while head < queue.length() {
    let current = queue[head]
    head += 1
    guard incoming.get(current) is Some(edges) else { continue }
    for edge in edges {
      if !seen.contains(edge.cell) {
        seen[edge.cell] = true
        next_edge[edge.cell] = edge
        queue.push(edge.cell)
      }
    }
  }
  let cells = []
  for cell in catalog.cells {
    if seen.contains(cell.name) {
      let witness = []
      let mut current = cell.name
      while next_edge.get(current) is Some(edge) {
        witness.push(edge)
        current = edge.target
      }
      cells.push({
        name: cell.name,
        is_top: catalog.top_cells.contains(cell.name),
        witness,
      })
    }
  }
  { target, target_defined: names.contains(target), cells, }
}
