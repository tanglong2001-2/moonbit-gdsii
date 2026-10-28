///|
/// Mutable AVL interval tree, indexed by (min_y, original rectangle id).
priv struct ActiveInterval {
  mut left : Int
  mut right : Int
  mut height : Int
  mut max_y : Int64
  mut id : Int
  mut low : Int64
  mut high : Int64
}

///|
fn height(nodes : Array[ActiveInterval], id : Int) -> Int {
  if id < 0 {
    0
  } else {
    nodes[id].height
  }
}

///|
fn update(nodes : Array[ActiveInterval], id : Int) -> Unit {
  let n = nodes[id]
  n.height = 1 + height(nodes, n.left).max(height(nodes, n.right))
  n.max_y = n.high
  if n.left >= 0 {
    n.max_y = n.max_y.max(nodes[n.left].max_y)
  }
  if n.right >= 0 {
    n.max_y = n.max_y.max(nodes[n.right].max_y)
  }
}

///|
fn rotate_left(nodes : Array[ActiveInterval], root : Int) -> Int {
  let r = nodes[root].right
  nodes[root].right = nodes[r].left
  nodes[r].left = root
  update(nodes, root)
  update(nodes, r)
  r
}

///|
fn rotate_right(nodes : Array[ActiveInterval], root : Int) -> Int {
  let l = nodes[root].left
  nodes[root].left = nodes[l].right
  nodes[l].right = root
  update(nodes, root)
  update(nodes, l)
  l
}

///|
fn balance(nodes : Array[ActiveInterval], root : Int) -> Int {
  update(nodes, root)
  let n = nodes[root]
  let skew = height(nodes, n.left) - height(nodes, n.right)
  if skew > 1 {
    let l = nodes[n.left]
    if height(nodes, l.left) < height(nodes, l.right) {
      n.left = rotate_left(nodes, n.left)
    }
    rotate_right(nodes, root)
  } else if skew < -1 {
    let r = nodes[n.right]
    if height(nodes, r.right) < height(nodes, r.left) {
      n.right = rotate_right(nodes, n.right)
    }
    rotate_left(nodes, root)
  } else {
    root
  }
}

///|
fn key_less(low : Int64, id : Int, other : ActiveInterval) -> Bool {
  low < other.low || (low == other.low && id < other.id)
}

///|
fn insert_interval(nodes : Array[ActiveInterval], root : Int, id : Int) -> Int {
  if root < 0 {
    return id
  }
  let n = nodes[root]
  if key_less(nodes[id].low, nodes[id].id, n) {
    n.left = insert_interval(nodes, n.left, id)
  } else {
    n.right = insert_interval(nodes, n.right, id)
  }
  balance(nodes, root)
}

///|
fn remove_interval(
  nodes : Array[ActiveInterval],
  root : Int,
  low : Int64,
  id : Int,
) -> Int {
  if root < 0 {
    return root
  }
  let n = nodes[root]
  if n.low == low && n.id == id {
    if n.left < 0 {
      return n.right
    }
    if n.right < 0 {
      return n.left
    }
    let mut successor = n.right
    while nodes[successor].left >= 0 {
      successor = nodes[successor].left
    }
    let s = nodes[successor]
    n.id = s.id
    n.low = s.low
    n.high = s.high
    n.right = remove_interval(nodes, n.right, s.low, s.id)
  } else if key_less(low, id, n) {
    n.left = remove_interval(nodes, n.left, low, id)
  } else {
    n.right = remove_interval(nodes, n.right, low, id)
  }
  balance(nodes, root)
}

///|
priv struct QueryStats {
  mut visits : Int64
}

///|
fn interval_candidates(
  nodes : Array[ActiveInterval],
  root : Int,
  low : Int64,
  high : Int64,
  result : Array[Int],
  stats : QueryStats,
) -> Unit {
  if root < 0 {
    return
  }
  stats.visits += 1L
  let n = nodes[root]
  if n.max_y <= low {
    return
  }
  interval_candidates(nodes, n.left, low, high, result, stats)
  if n.low < high && n.high > low {
    result.push(n.id)
  }
  if n.low < high {
    interval_candidates(nodes, n.right, low, high, result, stats)
  }
}

///|
/// Raw, unmerged boxes. Touching and overlapping boxes have zero spacing;
/// duplicate boxes are distinct instances. Strict thresholds: equality passes.
/// Sweep x events and an AVL y-interval index enumerate candidate pairs C.
/// Time O(N log N + V + C), output K <= C; V is reported index visits.
/// Euclidean corner filtering can make C larger than K; no O(N log N+K) claim.
pub fn check_manhattan_drc(
  rects : Array[Rect],
  min_width : Int,
  min_spacing : Int,
) -> Result[DrcReport, GdsError] {
  if min_width < 0 || min_spacing < 0 {
    return Err(InvalidGeometry("negative DRC threshold"))
  }
  let violations = []
  for i, r in rects {
    if r.min_x >= r.max_x || r.min_y >= r.max_y {
      return Err(InvalidGeometry("rectangle must have positive dimensions"))
    }
    let width = (r.max_x.to_int64() - r.min_x.to_int64()).min(
      r.max_y.to_int64() - r.min_y.to_int64(),
    )
    if width < min_width.to_int64() {
      violations.push(MinimumWidth(i, width))
    }
  }
  let mut candidates = 0L
  let stats : QueryStats = { visits: 0L, }
  if min_spacing > 0 {
    let starts = [ for i in 0..<rects.length() => i ]
    let ends = starts.copy()
    starts.sort_by(fn(a, b) {
      let c = rects[a].min_x.compare(rects[b].min_x)
      if c == 0 {
        a.compare(b)
      } else {
        c
      }
    })
    ends.sort_by(fn(a, b) {
      let c = rects[a].max_x.compare(rects[b].max_x)
      if c == 0 {
        a.compare(b)
      } else {
        c
      }
    })
    let nodes : Array[ActiveInterval] = [
      for i in 0..<rects.length() => {
        {
          left: -1,
          right: -1,
          height: 1,
          max_y: rects[i].max_y.to_int64(),
          id: i,
          low: rects[i].min_y.to_int64(),
          high: rects[i].max_y.to_int64(),
        }
      }
    ]
    let mut root = -1
    let mut expired = 0
    let spacing = min_spacing.to_int64()
    for id in starts {
      let r = rects[id]
      while expired < ends.length() &&
            rects[ends[expired]].max_x.to_int64() + spacing <=
            r.min_x.to_int64() {
        let old = ends[expired]
        root = remove_interval(nodes, root, rects[old].min_y.to_int64(), old)
        expired += 1
      }
      let ids = []
      interval_candidates(
        nodes,
        root,
        r.min_y.to_int64() - spacing,
        r.max_y.to_int64() + spacing,
        ids,
        stats,
      )
      for other in ids {
        candidates += 1L
        let s = rects[other]
        let dx = (r.min_x.to_int64() - s.max_x.to_int64())
          .max(s.min_x.to_int64() - r.max_x.to_int64())
          .max(0L)
        let dy = (r.min_y.to_int64() - s.max_y.to_int64())
          .max(s.min_y.to_int64() - r.max_y.to_int64())
          .max(0L)
        // Culling guarantees dx,dy < spacing <= INT32_MAX. Each square fits Int64.
        // Avoid adding the squares (their sum can overflow): compare by subtraction.
        if dx * dx < spacing * spacing - dy * dy {
          let distance = @math.hypot(dx.to_double(), dy.to_double())
          violations.push(
            MinimumSpacing(id.min(other), id.max(other), distance),
          )
        }
      }
      root = insert_interval(nodes, root, id)
    }
  }
  Ok({
    violations,
    candidates,
    index_visits: stats.visits,
    rectangles_checked: rects.length(),
  })
}
