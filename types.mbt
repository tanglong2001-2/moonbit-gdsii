///|
pub(all) suberror GdsError {
  InvalidRecord(Int, String)
  InvalidStructure(Int, String)
  InvalidNumber(String)
  MissingCell(String)
  CyclicReference(Array[String])
  ExpansionLimit(Int)
  CoordinateOverflow(Double)
  InvalidGeometry(String)
} derive(Debug, ToJson)

///|
/// Raw payloads are immutable Bytes; unknown records remain available for rewriting.
pub(all) struct GdsRecord {
  offset : Int
  kind : Int
  data_type : Int
  data : Bytes
} derive(Debug, ToJson)

///|
pub struct Real8Raw {
  bits : UInt64
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Point {
  x : Int
  y : Int
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Placement {
  reflection : Bool
  magnification : Double
  angle : Double
  absolute_magnification : Bool
  absolute_angle : Bool
} derive(Debug, ToJson)

///|
pub(all) enum ElementKind {
  Boundary
  Path
  Box
  Node
  Text
  Sref
  Aref
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Element {
  kind : ElementKind
  layer : Int
  datatype : Int
  points : Array[Point]
  target : String
  placement : Placement
  columns : Int
  rows : Int
  width : Int
  path_type : Int
  begin_extension : Int
  end_extension : Int
  text : String
  records : Array[GdsRecord]
} derive(Debug, ToJson)

///|
pub(all) struct Cell {
  name : String
  elements : Array[Element]
} derive(Debug, ToJson)

///|
pub struct GdsLibrary {
  name : String
  version : Int
  units_user : Real8Raw
  units_meters : Real8Raw
  records : Array[GdsRecord]
  cells : Array[Cell]
  padding : Bytes
} derive(Debug)

///|
pub(all) struct FlatShape {
  kind : ElementKind
  layer : Int
  datatype : Int
  points : Array[Point]
  source : String
  width : Double
  path_type : Int
  begin_extension : Double
  end_extension : Double
  text : String
  magnification : Double
  angle : Double
  reflection : Bool
} derive(Debug, ToJson)

///|
pub(all) struct FlattenedCell {
  name : String
  shapes : Array[FlatShape]
} derive(Debug, ToJson)

///|
pub(all) struct Rect {
  min_x : Int
  min_y : Int
  max_x : Int
  max_y : Int
  source : String
} derive(Debug, Eq, ToJson)

///|
pub(all) struct GeometryWarning {
  source : String
  reason : String
} derive(Debug, ToJson)

///|
pub(all) struct Rectangles {
  rects : Array[Rect]
  warnings : Array[GeometryWarning]
  layer : Int
  datatype : Int
} derive(Debug, ToJson)

///|
pub(all) enum DrcViolation {
  MinimumWidth(Int, Int64)
  MinimumSpacing(Int, Int, Double)
} derive(Debug, ToJson)

///|
pub(all) struct DrcReport {
  violations : Array[DrcViolation]
  candidates : Int64
  index_visits : Int64
  rectangles_checked : Int
} derive(Debug, ToJson)

///|
pub fn GdsLibrary::name(self : GdsLibrary) -> String {
  self.name
}

///|
pub fn GdsLibrary::version(self : GdsLibrary) -> Int {
  self.version
}

///|
pub fn GdsLibrary::units(self : GdsLibrary) -> (Real8Raw, Real8Raw) {
  (self.units_user, self.units_meters)
}

///|
/// A fresh semantic parse prevents edits to returned arrays mutating the library.
pub fn GdsLibrary::cells(self : GdsLibrary) -> Array[Cell] {
  (try! parse_library(self.to_bytes())).cells
}

///|
pub fn GdsLibrary::records(self : GdsLibrary) -> Array[GdsRecord] {
  self.records.copy()
}
