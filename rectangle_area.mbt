///|
priv struct AreaEvent {
  x : Int
  low : Int
  high : Int
  delta : Int
}

///|
priv struct AreaTree {
  ys : Array[Int]
  covers : Array[Int]
  lengths : Array[UInt64]
}

///|
fn AreaTree::change(
  self : AreaTree,
  node : Int,
  left : Int,
  right : Int,
  low : Int,
  high : Int,
  delta : Int,
) -> Unit {
  if low <= left && right <= high {
    self.covers[node] += delta
  } else {
    let middle = left + (right - left) / 2
    if low < middle {
      self.change(node * 2, left, middle, low, high, delta)
    }
    if high > middle {
      self.change(node * 2 + 1, middle, right, low, high, delta)
    }
  }
  self.lengths[node] = if self.covers[node] > 0 {
    (self.ys[right].to_int64() - self.ys[left].to_int64()).reinterpret_as_uint64()
  } else if right - left == 1 {
    0UL
  } else {
    self.lengths[node * 2] + self.lengths[node * 2 + 1]
  }
}

///|
/// Exact union area in squared integer DBU, with overlap/duplicates counted once.
/// Inputs must be positive INT32 rectangles, as for check_manhattan_drc; an empty
/// array has area zero. Source labels and order do not affect the result. Caller
/// arrays are not changed. Time O(N log N), additional memory O(N).
/// Differences are widened before subtraction; covered lengths and products are
/// UInt64. The union fits inside the full INT32-domain box, whose area is
/// (2^32-1)^2 < 2^64, so disjoint x-slab accumulation is exact without overflow.
/// This returns a scalar measurement, not merged polygons or a change to DRC.
/// Serialize the result as decimal text when a JSON number cannot preserve it.
/// ```mbt check
/// test {
///   let rectangles : Array[Rect] = [
///     { min_x: 0, min_y: 0, max_x: 4, max_y: 4, source: "a", },
///     { min_x: 2, min_y: 0, max_x: 6, max_y: 4, source: "b", },
///   ]
///   assert_eq(rectangle_union_area(rectangles).unwrap().to_string(), "24")
/// }
/// ```
pub fn rectangle_union_area(rects : Array[Rect]) -> Result[UInt64, GdsError] {
  let events : Array[AreaEvent] = []
  let endpoints : Array[Int] = []
  for rectangle in rects {
    if rectangle.min_x >= rectangle.max_x || rectangle.min_y >= rectangle.max_y {
      return Err(InvalidGeometry("rectangle must have positive dimensions"))
    }
    endpoints.push(rectangle.min_y)
    endpoints.push(rectangle.max_y)
    events.push({
      x: rectangle.min_x,
      low: rectangle.min_y,
      high: rectangle.max_y,
      delta: 1,
    })
    events.push({
      x: rectangle.max_x,
      low: rectangle.min_y,
      high: rectangle.max_y,
      delta: -1,
    })
  }
  if events.is_empty() {
    return Ok(0UL)
  }
  endpoints.sort_by(fn(a, b) { a.compare(b) })
  let ys : Array[Int] = []
  for value in endpoints {
    if ys.is_empty() || ys[ys.length() - 1] != value {
      ys.push(value)
    }
  }
  let positions : Map[Int, Int] = Map([])
  for index, value in ys {
    positions[value] = index
  }
  events.sort_by(fn(a, b) { a.x.compare(b.x) })
  let tree : AreaTree = {
    ys,
    covers: Array::make(ys.length() * 4, 0),
    lengths: Array::make(ys.length() * 4, 0UL),
  }
  let mut previous = events[0].x
  let mut area = 0UL
  for event in events {
    let width = (event.x.to_int64() - previous.to_int64()).reinterpret_as_uint64()
    // Before this x the tree describes exactly the active y-union. Equal-x
    // updates have zero slab width; their order cannot add or remove area.
    area += width * tree.lengths[1]
    tree.change(
      1,
      0,
      ys.length() - 1,
      positions[event.low],
      positions[event.high],
      event.delta,
    )
    previous = event.x
  }
  Ok(area)
}
