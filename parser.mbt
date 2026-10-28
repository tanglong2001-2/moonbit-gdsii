///|
fn parse_element(rs : Array[GdsRecord]) -> Element raise GdsError {
  let first = rs[0]
  require_record(first, 0, 0)
  let kind = match first.kind {
    8 => Boundary
    9 => Path
    10 => Sref
    11 => Aref
    12 => Text
    21 => Node
    45 => Box
    _ => raise InvalidStructure(first.offset, "invalid element")
  }
  let mut layer = -1
  let mut datatype = -1
  let mut points = []
  let mut target = ""
  let mut text = ""
  let mut columns = 1
  let mut rows = 1
  let mut width = 0
  let mut path_type = 0
  let mut begin_extension = 0
  let mut end_extension = 0
  let mut reflection = false
  let mut absolute_magnification = false
  let mut absolute_angle = false
  let mut magnification = 1.0
  let mut angle = 0.0
  let seen : Map[Int, Bool] = Map([])
  let mut property_open = false
  let mut last_rank = 0
  for i in 1..<rs.length() {
    let r = rs[i]
    let rank = match r.kind {
      38 => 1
      47 => 2
      13 | 18 => 10
      14 | 22 | 42 | 46 => 11
      23 => 12
      33 => 13
      15 => 14
      26 => 15
      27 | 48 => 16
      28 | 49 => 17
      19 => 18
      16 => 20
      25 => 21
      43 | 44 => 30
      _ => -1 // Unknown extensions have no known ordering or uniqueness contract.
    }
    if rank >= 0 {
      if rank < last_rank {
        raise InvalidStructure(r.offset, "element field order")
      }
      last_rank = rank
    }
    let allowed = match r.kind {
      13 => kind != Sref && kind != Aref
      14 => kind == Boundary || kind == Path
      22 | 23 | 25 => kind == Text
      42 => kind == Node
      46 => kind == Box
      15 | 33 => kind == Path || kind == Text
      18 => kind == Sref || kind == Aref
      19 => kind == Aref
      26 | 27 | 28 => kind == Sref || kind == Aref || kind == Text
      48 | 49 => kind == Path
      _ => true
    }
    if !allowed {
      raise InvalidStructure(r.offset, "field not allowed on this element")
    }
    if rank >= 0 && r.kind != 43 && r.kind != 44 {
      if seen.contains(r.kind) {
        raise InvalidStructure(r.offset, "duplicate element field")
      }
      seen[r.kind] = true
    }
    match r.kind {
      13 => {
        require_record(r, 2, 2)
        layer = uint16(r.data, 0)
      }
      14 | 22 | 42 | 46 => {
        require_record(r, 2, 2)
        datatype = uint16(r.data, 0)
      }
      15 => {
        require_record(r, 3, 4)
        width = int32(r.data, 0)
      }
      16 => {
        if r.data_type != 3 || r.data.length() < 8 || r.data.length() % 8 != 0 {
          raise InvalidRecord(r.offset, "XY requires coordinate pairs")
        }
        points = [
          for j in 0..<(r.data.length() / 8) => {
            { x: int32(r.data, j * 8), y: int32(r.data, j * 8 + 4), }
          }
        ]
      }
      18 => target = ascii(r)
      19 => {
        require_record(r, 2, 4)
        columns = int16(r.data, 0)
        rows = int16(r.data, 2)
        if columns <= 0 || rows <= 0 {
          raise InvalidRecord(r.offset, "COLROW must be positive")
        }
      }
      23 => require_record(r, 1, 2)
      25 => text = ascii(r)
      26 => {
        require_record(r, 1, 2)
        let flags = uint16(r.data, 0)
        if (flags & 0x7ff9) != 0 {
          raise InvalidRecord(r.offset, "reserved STRANS bits")
        }
        reflection = (flags & 0x8000) != 0
        absolute_magnification = (flags & 4) != 0
        absolute_angle = (flags & 2) != 0
      }
      27 => {
        require_record(r, 5, 8)
        magnification = real_at(r, 0).to_f64()
        if magnification <= 0.0 {
          raise InvalidNumber("MAG must be positive")
        }
      }
      28 => {
        require_record(r, 5, 8)
        angle = real_at(r, 0).to_f64()
      }
      33 => {
        require_record(r, 2, 2)
        path_type = int16(r.data, 0)
        if path_type != 0 && path_type != 1 && path_type != 2 && path_type != 4 {
          raise InvalidRecord(r.offset, "invalid PATHTYPE")
        }
      }
      38 => require_record(r, 1, 2)
      43 => {
        require_record(r, 2, 2)
        if property_open {
          raise InvalidStructure(r.offset, "property value missing")
        }
        property_open = true
      }
      44 => {
        let _ = ascii(r)
        if !property_open {
          raise InvalidStructure(r.offset, "property attribute missing")
        }
        property_open = false
      }
      47 => require_record(r, 3, 4)
      48 => {
        require_record(r, 3, 4)
        begin_extension = int32(r.data, 0)
      }
      49 => {
        require_record(r, 3, 4)
        end_extension = int32(r.data, 0)
      }
      _ => () // Unknown records are retained and do not claim semantic support.
    }
  }
  if property_open {
    raise InvalidStructure(first.offset, "property value missing")
  }
  let n = points.length()
  let reference = kind == Sref || kind == Aref
  if n == 0 ||
    (reference && target == "") ||
    (!reference && (layer < 0 || datatype < 0)) {
    raise InvalidStructure(first.offset, "required element field missing")
  }
  if reference && (seen.contains(13) || seen.contains(14)) {
    raise InvalidStructure(first.offset, "layer on reference")
  }
  let expected_type = match kind {
    Boundary | Path => 14
    Text => 22
    Node => 42
    Box => 46
    _ => -1
  }
  if expected_type >= 0 && !seen.contains(expected_type) {
    raise InvalidStructure(first.offset, "wrong type field")
  }
  if (kind == Sref || kind == Text) && n != 1 {
    raise InvalidStructure(first.offset, "one XY required")
  }
  if kind == Text && !seen.contains(25) {
    raise InvalidStructure(first.offset, "STRING missing")
  }
  if kind == Aref && (n != 3 || !seen.contains(19)) {
    raise InvalidStructure(first.offset, "AREF requires COLROW and three XY")
  }
  if (kind == Boundary && n < 4) ||
    (kind == Path && n < 2) ||
    (kind == Box && n != 5) ||
    (kind == Node && n > 50) {
    raise InvalidStructure(first.offset, "invalid vertex count")
  }
  if (kind == Boundary || kind == Box) && points[0] != points[n - 1] {
    raise InvalidStructure(first.offset, "boundary must be closed")
  }
  if (seen.contains(27) || seen.contains(28)) && !seen.contains(26) {
    raise InvalidStructure(first.offset, "MAG/ANGLE require STRANS")
  }
  if (seen.contains(48) || seen.contains(49)) && path_type != 4 {
    raise InvalidStructure(first.offset, "extensions require PATHTYPE 4")
  }
  {
    kind,
    layer,
    datatype,
    points,
    target,
    text,
    columns,
    rows,
    width,
    path_type,
    begin_extension,
    end_extension,
    records: rs,
    placement: {
      reflection,
      magnification,
      angle,
      absolute_magnification,
      absolute_angle,
    },
  }
}

///|
fn parse_library(bytes : Bytes) -> GdsLibrary raise GdsError {
  let records = read_records(bytes)
  // The stream grammar allows zero structures: the five library records suffice.
  if records.length() < 5 {
    raise InvalidStructure(0, "incomplete library")
  }
  if records[0].kind != 0 || records[1].kind != 1 {
    raise InvalidStructure(0, "HEADER/BGNLIB required")
  }
  require_record(records[0], 2, 2)
  require_record(records[1], 2, 24)
  let version = int16(records[0].data, 0)
  if version < 0 {
    raise InvalidStructure(0, "invalid stream version")
  }
  let mut name = ""
  let mut user : Real8Raw? = None
  let mut meters : Real8Raw? = None
  let cells = []
  let names : Map[String, Bool] = Map([])
  let mut cell_name : String? = None
  let mut elements = []
  let mut element_start = -1
  let mut ended = false
  for i in 2..<records.length() {
    let r = records[i]
    if element_start >= 0 {
      if r.kind == 17 {
        require_record(r, 0, 0)
        elements.push(parse_element(records[element_start:i].to_owned()))
        element_start = -1
      } else if r.kind == 0 ||
        r.kind == 1 ||
        r.kind == 2 ||
        r.kind == 3 ||
        r.kind == 5 ||
        r.kind == 6 ||
        r.kind == 7 ||
        r.kind == 4 ||
        r.kind == 8 ||
        r.kind == 9 ||
        r.kind == 10 ||
        r.kind == 11 ||
        r.kind == 12 ||
        r.kind == 21 ||
        r.kind == 45 {
        raise InvalidStructure(r.offset, "missing ENDEL")
      }
      continue
    }
    match r.kind {
      2 => {
        if name != "" || user is Some(_) || cell_name is Some(_) {
          raise InvalidStructure(r.offset, "unexpected LIBNAME")
        }
        name = ascii(r)
        if name == "" {
          raise InvalidStructure(r.offset, "empty library name")
        }
      }
      3 => {
        if name == "" || user is Some(_) || cell_name is Some(_) {
          raise InvalidStructure(r.offset, "unexpected UNITS")
        }
        require_record(r, 5, 16)
        let u = real_at(r, 0)
        let m = real_at(r, 8)
        if u.to_f64() <= 0.0 || m.to_f64() <= 0.0 {
          raise InvalidNumber("UNITS must be positive")
        }
        user = Some(u)
        meters = Some(m)
      }
      5 => {
        require_record(r, 2, 24)
        if user is None || cell_name is Some(_) {
          raise InvalidStructure(r.offset, "unexpected BGNSTR")
        }
        cell_name = Some("")
        elements = []
      }
      6 => {
        if cell_name != Some("") {
          raise InvalidStructure(r.offset, "unexpected STRNAME")
        }
        let value = ascii(r)
        if value == "" || names.contains(value) {
          raise InvalidStructure(r.offset, "empty or duplicate cell name")
        }
        names[value] = true
        cell_name = Some(value)
      }
      7 => {
        require_record(r, 0, 0)
        guard cell_name is Some(value) && value != "" else {
          raise InvalidStructure(r.offset, "unexpected ENDSTR")
        }
        cells.push({ name: value, elements, })
        cell_name = None
      }
      8 | 9 | 10 | 11 | 12 | 21 | 45 => {
        guard cell_name is Some(value) && value != "" else {
          raise InvalidStructure(r.offset, "element outside named cell")
        }
        element_start = i
      }
      4 => {
        require_record(r, 0, 0)
        if cell_name is Some(_) || i != records.length() - 1 {
          raise InvalidStructure(r.offset, "unexpected ENDLIB")
        }
        ended = true
      }
      0
      | 1
      | 13
      | 14
      | 15
      | 16
      | 17
      | 18
      | 19
      | 22
      | 23
      | 25
      | 26
      | 27
      | 28
      | 33
      | 38
      | 42
      | 43
      | 44
      | 46
      | 47
      | 48
      | 49 =>
        raise InvalidStructure(
          r.offset,
          "element or header record outside its scope",
        )
      _ => () // LIBDIRSIZE, SRFNAME, LIBSECUR, FORMAT etc remain raw records.
    }
  }
  guard user is Some(units_user) && meters is Some(units_meters) else {
    raise InvalidStructure(0, "UNITS missing")
  }
  if !ended || cell_name is Some(_) || element_start >= 0 {
    raise InvalidStructure(bytes.length(), "unterminated stream")
  }
  let last = records[records.length() - 1]
  let padding = bytes[last.offset + last.data.length() + 4:].to_owned()
  { name, version, units_user, units_meters, records, cells, padding, }
}

///|
pub fn GdsLibrary::parse(bytes : Bytes) -> Result[GdsLibrary, GdsError] {
  Ok(parse_library(bytes)) catch {
    e => Err(e)
  }
}
