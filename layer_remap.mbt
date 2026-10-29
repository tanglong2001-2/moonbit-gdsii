///|
/// One simultaneous original (layer, type) replacement. Values are UINT16;
/// type means DATATYPE, TEXTTYPE, NODETYPE or BOXTYPE for the element kind.
pub(all) struct LayerRemap {
  from_layer : Int
  from_type : Int
  to_layer : Int
  to_type : Int
} derive(Debug, ToJson)

///|
fn remap_tag_key(layer : Int, datatype : Int) -> Int64 {
  (layer.to_int64() << 16) | datatype.to_int64()
}

///|
/// Remap every supported layer-bearing definition, using its original tag once.
/// Duplicate sources or values outside 0..65535 reject the complete map, even
/// if an invalid rule would match no element. Empty/no-match/identity maps are
/// valid. Targets may coincide. References are not expanded or retargeted.
/// Only the matched tag payloads change: headers, offsets, geometry, properties,
/// unknown records, metadata and physical zero padding remain byte-exact.
/// The original library and the returned library have independent parsed arrays.
/// Example: an unused map on a valid empty library preserves its entire stream.
/// ```mbt check
/// test {
///   let library = GdsLibrary::parse(
///     b"\x00\x06\x00\x02\x02\x58\x00\x1c\x01\x02\x07\xea\x00\x0a\x00\x1d\x00\x12\x00\x00\x00\x00\x07\xea\x00\x0a\x00\x1d\x00\x12\x00\x00\x00\x00\x00\x0a\x02\x06\x52\x45\x4d\x41\x50\x00\x00\x08\x70\x02\x00\x01\x00\x02\x00\x14\x03\x05\x41\x10\x00\x00\x00\x00\x00\x00\x41\x10\x00\x00\x00\x00\x00\x00\x00\x04\x04\x00\x00\x00\x00\x00\x00\x00\x00",
///   ).unwrap()
///   let remapped = library
///     .remap_layers([{ from_layer: 1, from_type: 2, to_layer: 7, to_type: 8, }])
///     .unwrap()
///   assert_eq(remapped.to_bytes(), library.to_bytes())
/// }
/// ```
pub fn GdsLibrary::remap_layers(
  self : GdsLibrary,
  mappings : Array[LayerRemap],
) -> Result[GdsLibrary, GdsError] {
  let rules : Map[Int64, LayerRemap] = Map([])
  for mapping in mappings {
    for
      value in [
        mapping.from_layer,
        mapping.from_type,
        mapping.to_layer,
        mapping.to_type,
      ] {
      if value < 0 || value > 65535 {
        return Err(InvalidNumber("layer remap values must be UINT16 integers"))
      }
    }
    let key = remap_tag_key(mapping.from_layer, mapping.from_type)
    if rules.contains(key) {
      return Err(InvalidGeometry("duplicate layer remap source pair"))
    }
    rules[key] = mapping
  }
  let replacements : Map[Int, Int] = Map([])
  for cell in self.cells {
    for element in cell.elements {
      if element.kind == Sref || element.kind == Aref {
        continue
      }
      if rules.get(remap_tag_key(element.layer, element.datatype)) is Some(rule) {
        for record in element.records {
          match record.kind {
            13 => replacements[record.offset] = rule.to_layer
            14 | 22 | 42 | 46 => replacements[record.offset] = rule.to_type
            _ => ()
          }
        }
      }
    }
  }
  let out = @buffer.Buffer()
  for record in self.records {
    out.write_uint16_be((record.data.length() + 4).to_uint16())
    out.write_byte(record.kind.to_byte())
    out.write_byte(record.data_type.to_byte())
    if replacements.get(record.offset) is Some(value) {
      out.write_uint16_be(value.to_uint16())
    } else {
      out.write_bytes(record.data)
    }
  }
  out.write_bytes(self.padding)
  GdsLibrary::parse(out.to_bytes())
}
