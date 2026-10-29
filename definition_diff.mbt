///|
/// Zero-based record/byte range in the library's to_bytes output, including the
/// complete BGNSTR..ENDSTR block. Physical trailing padding is outside the range.
pub(all) struct CellRecordSpan {
  first_record : Int
  record_count : Int
  byte_offset : Int
  byte_length : Int
} derive(Debug, Eq, ToJson)

///|
pub(all) enum DefinitionStatus {
  DefinitionAdded
  DefinitionRemoved
  DefinitionChanged
  DefinitionUnchanged
} derive(Debug, Eq, ToJson)

///|
pub(all) struct CellDefinitionChange {
  name : String
  status : DefinitionStatus
  before : CellRecordSpan?
  after : CellRecordSpan?
} derive(Debug)

///|
/// JSON uses a nullable range object rather than the default Option encoding.
pub impl ToJson for CellDefinitionChange with fn to_json(self) -> Json {
  let before : Json = match self.before {
    None => Json::null()
    Some(span) => ToJson::to_json(span)
  }
  let after : Json = match self.after {
    None => Json::null()
    Some(span) => ToJson::to_json(span)
  }
  {
    "name": self.name,
    "status": ToJson::to_json(self.status),
    "before": before,
    "after": after,
  }
}

///|
/// Exact record inventory, not semantic layout or finding equivalence.
pub(all) struct DefinitionDiff {
  before_cells : Array[String]
  after_cells : Array[String]
  cells : Array[CellDefinitionChange]
  library_records_equal : Bool
  cell_order_equal : Bool
  padding_equal : Bool
  bytes_equal : Bool
  first_difference : Int?
} derive(Debug)

///|
pub impl ToJson for DefinitionDiff with fn to_json(self) -> Json {
  let first : Json = match self.first_difference {
    None => Json::null()
    Some(offset) => offset.to_json()
  }
  {
    "before_cells": self.before_cells.to_json(),
    "after_cells": self.after_cells.to_json(),
    "cells": self.cells.to_json(),
    "library_records_equal": self.library_records_equal,
    "cell_order_equal": self.cell_order_equal,
    "padding_equal": self.padding_equal,
    "bytes_equal": self.bytes_equal,
    "first_difference": first,
  }
}

///|
fn definition_record_spans(
  lib : GdsLibrary,
) -> (Array[CellRecordSpan], Array[GdsRecord]) {
  let spans = []
  let outside = []
  let mut start = -1
  // Validated framing pairs these blocks with lib.cells in source order;
  // opaque records are permitted before STRNAME and remain inside the block.
  for index, record in lib.records {
    match record.kind {
      5 => start = index
      7 => {
        let offset = lib.records[start].offset
        spans.push({
          first_record: start,
          record_count: index - start + 1,
          byte_offset: offset,
          byte_length: record.offset + 4 + record.data.length() - offset,
        })
        start = -1
      }
      _ => if start < 0 { outside.push(record) }
    }
  }
  (spans, outside)
}

///|
fn definition_records_equal(
  before : Array[GdsRecord],
  before_start : Int,
  before_count : Int,
  after : Array[GdsRecord],
  after_start : Int,
  after_count : Int,
) -> Bool {
  if before_count != after_count {
    return false
  }
  for i in 0..<before_count {
    let left = before[before_start + i]
    let right = after[after_start + i]
    if left.kind != right.kind ||
      left.data_type != right.data_type ||
      left.data != right.data {
      return false
    }
  }
  true
}

///|
/// Compare complete raw definitions by exact name, ignoring their file offsets.
/// Dates, properties, element order and unknown payloads all participate. Output
/// follows before order, then after-only names; renames are removal plus addition.
/// No hierarchy/geometry expansion occurs, even for missing or cyclic references.
///
/// library_records_equal compares the outside-cell record sequence, not its
/// placement among cells. Component flags cannot establish whole byte equality:
/// bytes_equal and first_difference independently inspect the full physical bytes.
/// A prefix mismatch is located at the shorter length. Returned arrays are fresh.
/// Example: two reads of this valid empty library have identical physical bytes.
/// ```mbt check
/// test {
///   let library = GdsLibrary::parse(
///     b"\x00\x06\x00\x02\x02\x58\x00\x1c\x01\x02\x07\xea\x00\x0a\x00\x1d\x00\x0d\x00\x00\x00\x00\x07\xea\x00\x0a\x00\x1d\x00\x0d\x00\x00\x00\x00\x00\x0e\x02\x06\x72\x61\x77\x2d\x72\x65\x76\x69\x65\x77\x00\x14\x03\x05\x41\x10\x00\x00\x00\x00\x00\x00\x41\x10\x00\x00\x00\x00\x00\x00\x00\x0e\x73\x06\x66\x6f\x72\x6d\x61\x74\x2d\x76\x31\x00\x00\x04\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00",
///   ).unwrap()
///   assert_eq(library.definition_diff(library).bytes_equal, true)
/// }
/// ```
pub fn GdsLibrary::definition_diff(
  self : GdsLibrary,
  after : GdsLibrary,
) -> DefinitionDiff {
  let (before_spans, before_outside) = definition_record_spans(self)
  let (after_spans, after_outside) = definition_record_spans(after)
  let before_cells = self.cells.map(fn(cell) { cell.name })
  let after_cells = after.cells.map(fn(cell) { cell.name })
  let before_names : Map[String, Bool] = Map([])
  let after_indices : Map[String, Int] = Map([])
  for index, cell in after.cells {
    after_indices[cell.name] = index
  }
  let cells = []
  for index, cell in self.cells {
    before_names[cell.name] = true
    let before = before_spans[index]
    match after_indices.get(cell.name) {
      None =>
        cells.push({
          name: cell.name,
          status: DefinitionRemoved,
          before: Some(before),
          after: None,
        })
      Some(i) => {
        let following = after_spans[i]
        let equal = definition_records_equal(
          self.records,
          before.first_record,
          before.record_count,
          after.records,
          following.first_record,
          following.record_count,
        )
        cells.push({
          name: cell.name,
          status: if equal {
            DefinitionUnchanged
          } else {
            DefinitionChanged
          },
          before: Some(before),
          after: Some(following),
        })
      }
    }
  }
  for index, cell in after.cells {
    if !before_names.contains(cell.name) {
      cells.push({
        name: cell.name,
        status: DefinitionAdded,
        before: None,
        after: Some(after_spans[index]),
      })
    }
  }
  let mut cell_order_equal = before_cells.length() == after_cells.length()
  if cell_order_equal {
    for i in 0..<before_cells.length() {
      if before_cells[i] != after_cells[i] {
        cell_order_equal = false
        break
      }
    }
  }
  let before_bytes = self.to_bytes()
  let after_bytes = after.to_bytes()
  let shorter = before_bytes.length().min(after_bytes.length())
  let mut first_difference : Int? = None
  for i in 0..<shorter {
    if before_bytes[i] != after_bytes[i] {
      first_difference = Some(i)
      break
    }
  }
  if first_difference is None && before_bytes.length() != after_bytes.length() {
    first_difference = Some(shorter)
  }
  {
    before_cells,
    after_cells,
    cells,
    library_records_equal: definition_records_equal(
      before_outside,
      0,
      before_outside.length(),
      after_outside,
      0,
      after_outside.length(),
    ),
    cell_order_equal,
    padding_equal: self.padding == after.padding,
    bytes_equal: first_difference is None,
    first_difference,
  }
}
