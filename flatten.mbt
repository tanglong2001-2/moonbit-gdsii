///|
priv struct Frame {
  x : Double
  y : Double
  mag : Scale
  angle : Double
  flip : Bool
}

///|
priv struct Expansion {
  mut used : Int
  limit : Int
}

///|
fn element_rotation(element : Element) -> Double {
  for record in element.records {
    if record.kind == 28 {
      return real_at(record, 0).rotation_degrees()
    }
  }
  0.0
}

///|
// Both operands of a composed rotation are already in (-180, 180].
fn compose_rotation(angle : Double) -> Double {
  if angle > 180.0 {
    angle - 360.0
  } else if angle <= -180.0 {
    angle + 360.0
  } else {
    angle
  }
}

///|
fn checked_metadata(
  value : Double,
  field : String,
  source : String,
) -> Double raise GdsError {
  if value.is_nan() || value.is_inf() {
    raise InvalidNumber(
      "transformed \{field} exceeds finite binary64 range at \{source}",
    )
  }
  value
}

///|
fn apply_point(f : Frame, x : Double, y : Double) -> (Double, Double) {
  let a = f.angle * @math.PI / 180.0
  let ca = @math.cos(a)
  let sa = @math.sin(a)
  let qx = f.mag.apply(x)
  let qy = f.mag.apply(y) * (if f.flip { -1.0 } else { 1.0 })
  (qx * ca - qy * sa + f.x, qx * sa + qy * ca + f.y)
}

///|
fn consume(budget : Expansion) -> Unit raise GdsError {
  if budget.used >= budget.limit {
    raise ExpansionLimit(budget.limit)
  }
  budget.used += 1
}

///|
fn walk_cell(
  lib : GdsLibrary,
  name : String,
  frame : Frame,
  source : String,
  stack : Array[String],
  budget : Expansion,
  output : Array[FlatShape],
) -> Unit raise GdsError {
  consume(budget)
  if stack.length() >= 256 {
    raise ExpansionLimit(budget.limit)
  }
  if stack.contains(name) {
    let path = stack.copy()
    path.push(name)
    raise CyclicReference(path)
  }
  guard lib.cells.search_by(fn(c) { c.name == name }) is Some(cell_index) else {
    raise MissingCell(name)
  }
  let cell = lib.cells[cell_index]
  stack.push(name)
  for index, element in cell.elements {
    let here = "\{source}/\{name}:\{index}"
    if element.kind == Sref || element.kind == Aref {
      let origin = element.points[0]
      let columns = element.columns
      let rows = element.rows
      if columns.to_int64() * rows.to_int64() >
        (budget.limit - budget.used).to_int64() {
        raise ExpansionLimit(budget.limit)
      }
      for row in 0..<rows {
        for col in 0..<columns {
          let x = origin.x.to_double() +
            (if element.kind == Aref {
              col.to_double() *
              (element.points[1].x.to_double() - origin.x.to_double()) /
              columns.to_double() +
              row.to_double() *
              (element.points[2].x.to_double() - origin.x.to_double()) /
              rows.to_double()
            } else {
              0.0
            })
          let y = origin.y.to_double() +
            (if element.kind == Aref {
              col.to_double() *
              (element.points[1].y.to_double() - origin.y.to_double()) /
              columns.to_double() +
              row.to_double() *
              (element.points[2].y.to_double() - origin.y.to_double()) /
              rows.to_double()
            } else {
              0.0
            })
          let (wx, wy) = apply_point(frame, x, y)
          let p = element.placement
          let angle = element_rotation(element)
          let child : Frame = {
            x: wx,
            y: wy,
            mag: if p.absolute_magnification {
              Scale::from_f64(p.magnification)
            } else {
              frame.mag.multiply(p.magnification)
            },
            angle: if p.absolute_angle {
              angle
            } else {
              compose_rotation(
                frame.angle + (if frame.flip { -angle } else { angle }),
              )
            },
            flip: frame.flip != p.reflection,
          }
          walk_cell(
            lib,
            element.target,
            child,
            "\{here}[\{col},\{row}]",
            stack,
            budget,
            output,
          )
        }
      }
    } else {
      consume(budget)
      let points = []
      for point in element.points {
        let (x, y) = apply_point(
          frame,
          point.x.to_double(),
          point.y.to_double(),
        )
        let x = match quantize_dbu(x) {
          Ok(n) => n
          Err(e) => raise e
        }
        let y = match quantize_dbu(y) {
          Ok(n) => n
          Err(e) => raise e
        }
        points.push({ x, y, })
      }
      let p = element.placement
      let angle = element_rotation(element)
      let width = checked_metadata(
        if element.width < 0 {
          -element.width.to_double()
        } else {
          frame.mag.apply(element.width.to_double())
        },
        "width",
        here,
      )
      let begin_extension = checked_metadata(
        frame.mag.apply(element.begin_extension.to_double()),
        "begin extension",
        here,
      )
      let end_extension = checked_metadata(
        frame.mag.apply(element.end_extension.to_double()),
        "end extension",
        here,
      )
      let magnification = checked_metadata(
        if p.absolute_magnification {
          p.magnification
        } else {
          frame.mag.multiply(p.magnification).to_f64()
        },
        "magnification",
        here,
      )
      output.push({
        kind: element.kind,
        layer: element.layer,
        datatype: element.datatype,
        points,
        source: here,
        width,
        path_type: element.path_type,
        begin_extension,
        end_extension,
        text: element.text,
        magnification,
        angle: if p.absolute_angle {
          angle
        } else {
          compose_rotation(
            frame.angle + (if frame.flip { -angle } else { angle }),
          )
        },
        reflection: frame.flip != p.reflection,
      })
    }
  }
  let _ = stack.pop()
}

///|
/// Coordinates remain floating point through the full chain and are quantized once.
/// Expansion budget counts visited instances and emitted shapes, including empty cells.
pub fn GdsLibrary::flatten_cell(
  self : GdsLibrary,
  cell_name : String,
  budget? : Int = 100000,
) -> Result[FlattenedCell, GdsError] {
  if budget <= 0 {
    return Err(ExpansionLimit(budget))
  }
  try {
    let shapes = []
    walk_cell(
      self,
      cell_name,
      { x: 0.0, y: 0.0, mag: Scale::from_f64(1.0), angle: 0.0, flip: false, },
      "",
      [],
      { used: 0, limit: budget, },
      shapes,
    )
    Ok({ name: cell_name, shapes, })
  } catch {
    e => Err(e)
  }
}

///|
fn identify_rectangle(shape : FlatShape) -> Rect? {
  if shape.kind != Boundary && shape.kind != Box {
    return None
  }
  let ps = shape.points
  if ps.length() < 5 || ps[0] != ps[ps.length() - 1] {
    return None
  }
  // Remove redundant collinear points without accepting retraced or self-crossing rings.
  let corners = []
  for i in 0..<(ps.length() - 1) {
    let prev = ps[(i + ps.length() - 2) % (ps.length() - 1)]
    let p = ps[i]
    let next = ps[i + 1]
    if p == next {
      return None
    }
    if p.x != next.x && p.y != next.y {
      return None
    }
    if (prev.x == p.x && p.x == next.x) || (prev.y == p.y && p.y == next.y) {
      // A collinear reversal is not a simple box.
      let dx1 = p.x.to_int64() - prev.x.to_int64()
      let dy1 = p.y.to_int64() - prev.y.to_int64()
      let dx2 = next.x.to_int64() - p.x.to_int64()
      let dy2 = next.y.to_int64() - p.y.to_int64()
      if (dx1 > 0L) != (dx2 > 0L) || (dy1 > 0L) != (dy2 > 0L) {
        return None
      }
    } else {
      corners.push(p)
    }
  }
  if corners.length() != 4 {
    return None
  }
  let mut x0 = corners[0].x
  let mut x1 = x0
  let mut y0 = corners[0].y
  let mut y1 = y0
  for p in corners {
    x0 = x0.min(p.x)
    x1 = x1.max(p.x)
    y0 = y0.min(p.y)
    y1 = y1.max(p.y)
  }
  if x0 == x1 || y0 == y1 {
    return None
  }
  for i in 0..<4 {
    let p = corners[i]
    if (p.x != x0 && p.x != x1) || (p.y != y0 && p.y != y1) {
      return None
    }
    for j in 0..<i {
      if p == corners[j] {
        return None
      }
    }
  }
  Some({ min_x: x0, min_y: y0, max_x: x1, max_y: y1, source: shape.source, })
}

///|
/// Explicit single (layer, datatype) selection. Every unhandled selected shape is reported.
pub fn FlattenedCell::rectangles(
  self : FlattenedCell,
  layer : Int,
  datatype : Int,
) -> Rectangles {
  let rects = []
  let warnings = []
  for shape in self.shapes {
    if shape.layer != layer || shape.datatype != datatype {
      continue
    }
    match identify_rectangle(shape) {
      Some(rect) => rects.push(rect)
      None =>
        warnings.push({
          source: shape.source,
          reason: "GeometrySkipped: not a nondegenerate simple axis-aligned box (PATH/TEXT/NODE also retained but not stroked)",
        })
    }
  }
  { rects, warnings, layer, datatype, }
}
