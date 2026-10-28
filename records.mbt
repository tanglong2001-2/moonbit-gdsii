///|
fn uint16(bytes : Bytes, at : Int) -> Int {
  bytes[at].to_int() * 256 + bytes[at + 1].to_int()
}

///|
fn int16(bytes : Bytes, at : Int) -> Int {
  let n = uint16(bytes, at)
  if n >= 32768 {
    n - 65536
  } else {
    n
  }
}

///|
fn int32(bytes : Bytes, at : Int) -> Int {
  (bytes[at].to_int() << 24) |
  (bytes[at + 1].to_int() << 16) |
  (bytes[at + 2].to_int() << 8) |
  bytes[at + 3].to_int()
}

///|
fn require_record(
  r : GdsRecord,
  dtype : Int,
  size : Int,
) -> Unit raise GdsError {
  if r.data_type != dtype || r.data.length() != size {
    raise InvalidRecord(r.offset, "record type/size mismatch: \{r.kind}")
  }
}

///|
fn ascii(r : GdsRecord) -> String raise GdsError {
  if r.data_type != 6 {
    raise InvalidRecord(r.offset, "ASCII type required")
  }
  let mut end = r.data.length()
  if end > 0 && r.data[end - 1] == 0 {
    end -= 1
  }
  for i in 0..<end {
    if r.data[i] == 0 || r.data[i] > 127 {
      raise InvalidRecord(r.offset, "invalid ASCII")
    }
  }
  try! @utf8.decode(r.data[:end])
}

///|
fn real_at(r : GdsRecord, at : Int) -> Real8Raw {
  let mut bits = 0UL
  for i in at..<(at + 8) {
    bits = (bits << 8) | r.data[i].to_uint64()
  }
  { bits, }
}

///|
fn read_records(bytes : Bytes) -> Array[GdsRecord] raise GdsError {
  let records : Array[GdsRecord] = []
  let mut pos = 0
  while pos < bytes.length() {
    if !records.is_empty() && records[records.length() - 1].kind == 4 {
      for i in pos..<bytes.length() {
        if bytes[i] != 0 {
          raise InvalidRecord(i, "nonzero bytes after ENDLIB")
        }
      }
      break
    }
    if bytes.length() - pos < 4 {
      raise InvalidRecord(pos, "truncated header")
    }
    let size = uint16(bytes, pos)
    if size < 4 || size % 2 != 0 || size > bytes.length() - pos {
      raise InvalidRecord(pos, "invalid or truncated record length")
    }
    let dtype = bytes[pos + 3].to_int()
    let payload = size - 4
    let alignment = match dtype {
      0 => 1
      1 | 2 => 2
      3 | 4 => 4
      5 => 8
      6 => 2
      _ => 0
    }
    if alignment == 0 ||
      payload % alignment != 0 ||
      (dtype == 0 && payload != 0) {
      raise InvalidRecord(pos, "invalid data type or alignment")
    }
    records.push({
      offset: pos,
      kind: bytes[pos + 2].to_int(),
      data_type: dtype,
      data: bytes[pos + 4:pos + size].to_owned(),
    })
    pos += size
  }
  records
}

///|
/// Byte-preserving record writer. Semantic creation is checked via from_records.
pub fn GdsLibrary::to_bytes(self : GdsLibrary) -> Bytes {
  let out = @buffer.Buffer()
  for r in self.records {
    out.write_uint16_be((r.data.length() + 4).to_uint16())
    out.write_byte(r.kind.to_byte())
    out.write_byte(r.data_type.to_byte())
    out.write_bytes(r.data)
  }
  out.write_bytes(self.padding)
  out.to_bytes()
}

///|
pub fn GdsLibrary::from_records(
  records : Array[GdsRecord],
) -> Result[GdsLibrary, GdsError] {
  let out = @buffer.Buffer()
  for r in records {
    if r.kind < 0 ||
      r.kind > 255 ||
      r.data_type < 0 ||
      r.data_type > 6 ||
      r.data.length() > 65530 {
      return Err(InvalidRecord(r.offset, "record cannot be serialized"))
    }
    out.write_uint16_be((r.data.length() + 4).to_uint16())
    out.write_byte(r.kind.to_byte())
    out.write_byte(r.data_type.to_byte())
    out.write_bytes(r.data)
  }
  GdsLibrary::parse(out.to_bytes())
}
