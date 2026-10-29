///|
fn rename_name_data(name : String) -> Bytes {
  let data = @utf8.encode(name)
  if data.length() % 2 == 0 {
    return data
  }
  let out = @buffer.Buffer()
  out.write_bytes(data)
  out.write_byte(0)
  out.to_bytes()
}

///|
/// Rename one definition and every exact supported SNAME use, without capturing
/// an existing definition or a previously unresolved destination reference.
/// Other payloads stay raw. A real edit follows from_records offset/padding rules;
/// an existing-name no-op preserves all bytes, including physical tail padding.
/// Existing checked serialization/parsing validates the new ASCII record name.
pub fn GdsLibrary::rename_cell(
  self : GdsLibrary,
  old_name : String,
  new_name : String,
) -> Result[GdsLibrary, GdsError] {
  guard self.cells.search_by(fn(cell) { cell.name == old_name }) is Some(_) else {
    return Err(MissingCell(old_name))
  }
  if old_name == new_name {
    return GdsLibrary::parse(self.to_bytes())
  }
  if self.cells.search_by(fn(cell) { cell.name == new_name }) is Some(_) {
    return Err(InvalidGeometry("destination cell name already exists"))
  }
  for reference in self.catalog().missing_references {
    if reference.target == new_name {
      return Err(
        InvalidGeometry(
          "destination name is already an unresolved reference target",
        ),
      )
    }
  }
  let old_data = rename_name_data(old_name)
  let new_data = rename_name_data(new_name)
  let records = []
  for record in self.records {
    if (record.kind == 6 || record.kind == 18) && record.data == old_data {
      records.push({
        offset: record.offset,
        kind: record.kind,
        data_type: record.data_type,
        data: new_data,
      })
    } else {
      records.push(record)
    }
  }
  GdsLibrary::from_records(records)
}
