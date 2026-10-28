///|
/// Selected-root definition inventory, without expanding instances. A cycle is
/// one closed witness, not an exhaustive list. Findings do not certify geometry.
pub(all) struct HierarchyReport {
  cell : String
  reachable_cells : Array[String]
  layers : Array[LayerUsage]
  references : Array[CatalogReference]
  missing_references : Array[CatalogReference]
  cycle : Array[String]
} derive(Debug, ToJson)

///|
fn merge_hierarchy_layer(
  layers : Array[LayerUsage],
  indices : Map[Int64, Int],
  usage : LayerUsage,
) -> Unit {
  let kind_code = match usage.kind {
    Boundary => 0
    Path => 1
    Box => 2
    Node => 3
    Text => 4
    _ => 5
  }
  let key = (kind_code.to_int64() << 32) |
    (usage.layer.to_int64() << 16) |
    usage.datatype.to_int64()
  match indices.get(key) {
    Some(index) =>
      layers[index] = {
        kind: usage.kind,
        layer: usage.layer,
        datatype: usage.datatype,
        elements: layers[index].elements + usage.elements,
      }
    None => {
      indices[key] = layers.length()
      layers.push(usage)
    }
  }
}

///|
/// Inspect cells reachable from a selected cell, including that cell. Counts
/// include each reachable definition once. Output follows file/first-layer order.
/// Missing descendants and one cycle witness are findings; a missing selected
/// cell returns MissingCell. No transform, array expansion or recursion occurs.
pub fn GdsLibrary::hierarchy(
  self : GdsLibrary,
  cell : String,
) -> Result[HierarchyReport, GdsError] {
  let catalog = self.catalog()
  let indices : Map[String, Int] = Map([])
  for index, entry in catalog.cells {
    indices[entry.name] = index
  }
  guard indices.get(cell) is Some(root) else { return Err(MissingCell(cell)) }
  // 0: unseen, 1: on the current DFS path, 2: completely visited.
  // A shared descendant reached again in state 2 is not a cycle.
  let colors : Array[Int] = [ for _ in 0..<catalog.cells.length() => 0 ]
  let next_reference : Array[Int] = [ for _ in 0..<catalog.cells.length() => 0 ]
  let stack = [root]
  let cycle = []
  colors[root] = 1
  while !stack.is_empty() {
    let current = stack[stack.length() - 1]
    let references = catalog.cells[current].references
    let next = next_reference[current]
    if next == references.length() {
      colors[current] = 2
      let _ = stack.pop()
      continue
    }
    next_reference[current] = next + 1
    guard indices.get(references[next].target) is Some(target) else { continue }
    if colors[target] == 0 {
      colors[target] = 1
      stack.push(target)
    } else if colors[target] == 1 && cycle.is_empty() {
      let mut start = 0
      while stack[start] != target {
        start += 1
      }
      for i in start..<stack.length() {
        cycle.push(catalog.cells[stack[i]].name)
      }
      cycle.push(catalog.cells[target].name)
    }
  }
  let reachable_cells = []
  let layers = []
  let layer_indices : Map[Int64, Int] = Map([])
  let references = []
  let missing_references = []
  for index, entry in catalog.cells {
    if colors[index] == 0 {
      continue
    }
    reachable_cells.push(entry.name)
    for usage in entry.layers {
      merge_hierarchy_layer(layers, layer_indices, usage)
    }
    for reference in entry.references {
      references.push(reference)
      if !reference.resolved {
        missing_references.push(reference)
      }
    }
  }
  Ok({ cell, reachable_cells, layers, references, missing_references, cycle, })
}
