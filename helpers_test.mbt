///|
fn compare_points(a : Array[(Int, Int)], b : Array[(Int, Int)]) -> Int {
  for i in 0..<a.length().min(b.length()) {
    let c = a[i].0.compare(b[i].0)
    if c != 0 {
      return c
    }
    let c = a[i].1.compare(b[i].1)
    if c != 0 {
      return c
    }
  }
  a.length().compare(b.length())
}

///|
fn normalized_polygons(flat : @gdsii.FlattenedCell) -> Array[Array[(Int, Int)]] {
  let out = []
  for shape in flat.shapes {
    if shape.kind != @gdsii.Boundary && shape.kind != @gdsii.Box {
      continue
    }
    let ps = shape.points
    let n = if ps[0] == ps[ps.length() - 1] {
      ps.length() - 1
    } else {
      ps.length()
    }
    let mut best : Array[(Int, Int)] = [ for i in 0..<n => (ps[i].x, ps[i].y) ]
    for start in 0..<n {
      for direction in [-1, 1] {
        let candidate = [
          for j in 0..<n => {
            let p = ps[(start + direction * j + n) % n]
            (p.x, p.y)
          }
        ]
        if compare_points(candidate, best) < 0 {
          best = candidate
        }
      }
    }
    out.push(best)
  }
  out.sort_by(compare_points)
  out
}
