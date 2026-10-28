///|
/// A count of element definitions on one layer/type, distinguished by kind.
pub(all) struct LayerUsage {
  kind : ElementKind
  layer : Int
  datatype : Int
  elements : Int
} derive(Debug, ToJson)

///|
/// A reference definition, not its expanded geometry. Indices are zero-based.
pub(all) struct CatalogReference {
  cell : String
  element_index : Int
  kind : ElementKind
  target : String
  columns : Int
  rows : Int
  instances : Int
  resolved : Bool
} derive(Debug, ToJson)

///|
pub(all) struct CatalogCell {
  name : String
  elements : Int
  layers : Array[LayerUsage]
  references : Array[CatalogReference]
} derive(Debug, ToJson)

///|
/// Definition inventory. Top cells have no incoming references; cycles may have
/// no top cells. This report does not certify hierarchy or geometry validity.
pub(all) struct GdsCatalog {
  name : String
  version : Int
  dbu_in_user_units : Double
  dbu_in_meters : Double
  cells : Array[CatalogCell]
  top_cells : Array[String]
  missing_references : Array[CatalogReference]
} derive(Debug, ToJson)

///|
/// Inspect definitions without expanding references or applying transforms.
/// Cells follow source order; layer entries follow their first occurrence.
/// Returned arrays are new and cannot mutate the original library.
pub fn GdsLibrary::catalog(self : GdsLibrary) -> GdsCatalog {
  let names : Map[String, Bool] = Map([])
  for cell in self.cells {
    names[cell.name] = true
  }
  let incoming : Map[String, Bool] = Map([])
  let cells = []
  let missing_references = []
  for cell in self.cells {
    let layers : Array[LayerUsage] = []
    let layer_index : Map[Int64, Int] = Map([])
    let references = []
    for index, element in cell.elements {
      if element.kind == Sref || element.kind == Aref {
        let reference : CatalogReference = {
          cell: cell.name,
          element_index: index,
          kind: element.kind,
          target: element.target,
          columns: element.columns,
          rows: element.rows,
          // Each COLROW component is at most 32767: the product fits INT32.
          instances: element.columns * element.rows,
          resolved: names.contains(element.target),
        }
        incoming[element.target] = true
        references.push(reference)
        if !reference.resolved {
          missing_references.push(reference)
        }
      } else {
        let kind_code = match element.kind {
          Boundary => 0
          Path => 1
          Box => 2
          Node => 3
          Text => 4
          _ => 5
        }
        let key = (kind_code.to_int64() << 32) |
          (element.layer.to_int64() << 16) |
          element.datatype.to_int64()
        let count = match layer_index.get(key) {
          Some(i) => {
            let count = layers[i].elements + 1
            layers[i] = {
              kind: element.kind,
              layer: element.layer,
              datatype: element.datatype,
              elements: count,
            }
            count
          }
          None => 0
        }
        if count == 0 {
          layer_index[key] = layers.length()
          layers.push({
            kind: element.kind,
            layer: element.layer,
            datatype: element.datatype,
            elements: 1,
          })
        }
      }
    }
    cells.push({
      name: cell.name,
      elements: cell.elements.length(),
      layers,
      references,
    })
  }
  let top_cells = []
  for cell in self.cells {
    if !incoming.contains(cell.name) {
      top_cells.push(cell.name)
    }
  }
  {
    name: self.name,
    version: self.version,
    dbu_in_user_units: self.units_user.to_f64(),
    dbu_in_meters: self.units_meters.to_f64(),
    cells,
    top_cells,
    missing_references,
  }
}
