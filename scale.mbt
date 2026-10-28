///|
// A positive binary64 significand with a separate, hierarchy-sized exponent.
// Delay range rounding until a coordinate or output metadata value is needed.
priv struct Scale {
  fraction : Double
  exponent : Int
}

///|
fn Scale::from_f64(value : Double) -> Scale {
  let mut bits = value.reinterpret_as_uint64()
  let mut adjustment = 0
  if ((bits >> 52) & 0x7ffUL) == 0UL {
    bits = (value * 4503599627370496.0).reinterpret_as_uint64()
    adjustment = -52
  }
  {
    fraction: ((bits & 0x000fffffffffffffUL) | 0x3ff0000000000000UL).reinterpret_as_double(),
    exponent: ((bits >> 52) & 0x7ffUL).to_int() - 1023 + adjustment,
  }
}

///|
fn Scale::multiply(self : Scale, value : Double) -> Scale {
  let other = Scale::from_f64(value)
  let fraction = self.fraction * other.fraction
  if fraction >= 2.0 {
    { fraction: fraction / 2.0, exponent: self.exponent + other.exponent + 1, }
  } else {
    { fraction, exponent: self.exponent + other.exponent, }
  }
}

///|
fn Scale::to_f64(self : Scale) -> Double {
  if self.exponent > 1023 {
    return 0x7ff0000000000000UL.reinterpret_as_double()
  }
  if self.exponent < -1075 {
    return 0.0
  }
  if self.exponent >= -1022 {
    self.fraction *
    ((self.exponent + 1023).to_uint64() << 52).reinterpret_as_double()
  } else {
    // The first product is exact and normal; only the final product rounds
    // to subnormal, including half-minimum ties and their immediate neighbors.
    self.fraction *
    0x0010000000000000UL.reinterpret_as_double() *
    @math.pow(2.0, (self.exponent + 1022).to_double())
  }
}

///|
fn Scale::apply(self : Scale, value : Double) -> Double {
  if value == 0.0 {
    return value
  }
  let result = self.multiply(value.abs()).to_f64()
  if value < 0.0 {
    -result
  } else {
    result
  }
}
