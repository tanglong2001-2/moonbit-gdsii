///|
/// Accept every eight-byte encoding, including noncanonical encodings, without changing bits.
pub fn Real8Raw::from_bytes(bytes : Bytes) -> Result[Real8Raw, GdsError] {
  if bytes.length() != 8 {
    return Err(InvalidNumber("REAL8 requires eight bytes"))
  }
  let mut bits = 0UL
  for b in bytes {
    bits = (bits << 8) | b.to_uint64()
  }
  Ok({ bits, })
}

///|
pub fn Real8Raw::to_bytes(self : Real8Raw) -> Bytes {
  self.bits.to_be_bytes()
}

///|
/// The integer-to-Double conversion rounds to nearest, ties to even. Scaling is exact.
pub fn Real8Raw::to_f64(self : Real8Raw) -> Double {
  let mantissa = self.bits & 0x00ffffffffffffffUL
  if mantissa == 0UL {
    return 0.0
  }
  let exponent = ((self.bits >> 56) & 127UL).to_int()
  let value = mantissa.to_double() *
    @math.pow(2.0, (4 * (exponent - 64) - 56).to_double())
  if self.bits >> 63 == 0UL {
    value
  } else {
    -value
  }
}

///|
/// Canonical normalized encoding of finite Double values in REAL8's normalized range.
/// IEEE binary64 values in this domain are exactly representable. Underflow/overflow
/// is an error; raw preservation is a separate API. Both signed zeros encode as zero.
pub fn Real8Raw::from_f64(value : Double) -> Result[Real8Raw, GdsError] {
  if value.is_nan() || value.is_inf() {
    return Err(InvalidNumber("non-finite REAL8"))
  }
  if value == 0.0 {
    return Ok({ bits: 0UL, })
  }
  let mut fraction = value.abs()
  let mut exponent = 64
  while fraction >= 1.0 && exponent <= 127 {
    fraction /= 16.0
    exponent += 1
  }
  while fraction < 0.0625 && exponent >= 0 {
    fraction *= 16.0
    exponent -= 1
  }
  if exponent < 0 || exponent > 127 {
    return Err(InvalidNumber("REAL8 normalized range exceeded"))
  }
  let mantissa = (fraction * 72057594037927936.0).to_uint64()
  let sign = if value < 0.0 { 0x8000000000000000UL } else { 0UL }
  Ok({ bits: sign | (exponent.to_uint64() << 56) | mantissa, })
}

///|
// Reduce the exact encoded angle before narrowing its fraction to binary64.
// Large REAL8 angles can have a different remainder than their rounded Double.
fn Real8Raw::rotation_degrees(self : Real8Raw) -> Double {
  let mantissa = self.bits & 0x00ffffffffffffffUL
  let exponent = ((self.bits >> 56) & 127UL).to_int()
  let shift = 4 * (exponent - 64) - 56
  let negative = self.bits >> 63 != 0UL
  let mut angle = if shift >= 0 {
    let mut remainder = (mantissa % 360UL).to_int()
    for _ in 0..<shift {
      remainder = remainder * 2 % 360
    }
    if remainder > 180 {
      (remainder - 360).to_double()
    } else {
      remainder.to_double()
    }
  } else {
    let fractional_bits = -shift
    if fractional_bits >= 56 {
      // The magnitude is less than one degree: no full turn can be removed.
      return self.to_f64()
    }
    // fractional_bits <= 55, hence 360 * 2^fractional_bits fits UInt64.
    let modulus = 360UL << fractional_bits
    let half_turn = 180UL << fractional_bits
    let remainder = mantissa % modulus
    let scale = @math.pow(2.0, shift.to_double())
    if remainder > half_turn {
      -(modulus - remainder).to_double() * scale
    } else {
      remainder.to_double() * scale
    }
  }
  if negative {
    angle = -angle
  }
  if angle == -180.0 {
    180.0
  } else {
    angle
  }
}

///|
/// Nearest DBU integer; half cases go away from zero, only once after flattening.
pub fn quantize_dbu(value : Double) -> Result[Int, GdsError] {
  if value.is_nan() || value.is_inf() {
    return Err(CoordinateOverflow(value))
  }
  // Adding 0.5 first double-rounds the predecessor of 0.5 to 1.0.
  // Below 2^52 the fractional subtraction is exact; above it every finite
  // binary64 value is already integral. Compare the remainder before adding 1.
  let magnitude = value.abs()
  let integral = @math.floor(magnitude)
  let nearest = if magnitude - integral >= 0.5 {
    integral + 1.0
  } else {
    integral
  }
  let rounded = if value < 0.0 { -nearest } else { nearest }
  if rounded < -2147483648.0 || rounded > 2147483647.0 {
    Err(CoordinateOverflow(value))
  } else {
    Ok(rounded.to_int())
  }
}
