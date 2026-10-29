///|
test "rectangle union area hand geometry and same-x events" {
  {
    let rectangles : Array[@gdsii.Rect] = []
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "0")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 0, max_x: 4, max_y: 3, source: "item-0", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "12",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 0, max_x: 4, max_y: 4, source: "item-0", },
      { min_x: 2, min_y: 0, max_x: 6, max_y: 4, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "24",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 0, max_x: 6, max_y: 6, source: "item-0", },
      { min_x: 1, min_y: 1, max_x: 5, max_y: 5, source: "item-1", },
      { min_x: 0, min_y: 0, max_x: 6, max_y: 6, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "36",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 0, max_x: 2, max_y: 2, source: "item-0", },
      { min_x: 2, min_y: 0, max_x: 4, max_y: 2, source: "item-1", },
      { min_x: 4, min_y: 2, max_x: 6, max_y: 4, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "12",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 0, max_x: 6, max_y: 1, source: "item-0", },
      { min_x: 0, min_y: 5, max_x: 6, max_y: 6, source: "item-1", },
      { min_x: 0, min_y: 1, max_x: 1, max_y: 5, source: "item-2", },
      { min_x: 5, min_y: 1, max_x: 6, max_y: 5, source: "item-3", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "20",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -2, max_x: 0, max_y: 2, source: "item-0", },
      { min_x: 0, min_y: -2, max_x: 3, max_y: 2, source: "item-1", },
      { min_x: 0, min_y: -1, max_x: 4, max_y: 1, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "26",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -3, max_x: 1, max_y: 1, source: "item-0", },
      { min_x: -1, min_y: -1, max_x: 3, max_y: 3, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "28",
    )
  }
  let rectangles : Array[@gdsii.Rect] = [
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-0", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-1", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-2", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-3", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-4", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-5", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-6", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-7", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-8", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-9", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-10", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-11", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-12", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-13", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-14", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-15", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-16", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-17", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-18", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-19", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-20", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-21", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-22", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-23", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-24", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-25", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-26", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-27", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-28", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-29", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-30", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-31", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "item-32", },
  ]
  assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "1")
}

///|
test "rectangle union area64 independent unit-square occupancy cases" {
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: 1, max_x: 3, max_y: 3, source: "item-0", },
      { min_x: -2, min_y: 2, max_x: 0, max_y: 3, source: "item-1", },
      { min_x: -3, min_y: -2, max_x: 0, max_y: 0, source: "item-2", },
      { min_x: -1, min_y: -2, max_x: 2, max_y: 4, source: "item-3", },
      { min_x: 0, min_y: -3, max_x: 1, max_y: -1, source: "item-4", },
      { min_x: -3, min_y: -1, max_x: 1, max_y: 0, source: "item-5", },
      { min_x: 2, min_y: -1, max_x: 3, max_y: 4, source: "item-6", },
      { min_x: -3, min_y: -3, max_x: 4, max_y: -2, source: "item-7", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "35",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: 0, max_x: -1, max_y: 3, source: "item-0", },
      { min_x: -2, min_y: -2, max_x: 2, max_y: 2, source: "item-1", },
      { min_x: 3, min_y: 2, max_x: 4, max_y: 4, source: "item-2", },
      { min_x: -4, min_y: -4, max_x: 3, max_y: 0, source: "item-3", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "42",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 2, min_y: -2, max_x: 3, max_y: 1, source: "item-0", },
      { min_x: 3, min_y: -2, max_x: 4, max_y: 0, source: "item-1", },
      { min_x: -3, min_y: 1, max_x: 1, max_y: 4, source: "item-2", },
      { min_x: 0, min_y: 2, max_x: 3, max_y: 3, source: "item-3", },
      { min_x: 0, min_y: 0, max_x: 2, max_y: 3, source: "item-4", },
      { min_x: -4, min_y: -1, max_x: -2, max_y: 2, source: "item-5", },
      { min_x: 0, min_y: 1, max_x: 3, max_y: 4, source: "item-6", },
      { min_x: -2, min_y: 3, max_x: 0, max_y: 4, source: "item-7", },
      { min_x: -1, min_y: -2, max_x: 2, max_y: 4, source: "item-8", },
      { min_x: -1, min_y: -4, max_x: 3, max_y: 1, source: "item-9", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "45",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 1, min_y: -3, max_x: 2, max_y: -2, source: "item-0", },
      { min_x: -4, min_y: -1, max_x: -3, max_y: 4, source: "item-1", },
      { min_x: -3, min_y: 1, max_x: 4, max_y: 2, source: "item-2", },
      { min_x: -3, min_y: -1, max_x: 3, max_y: 0, source: "item-3", },
      { min_x: -2, min_y: 0, max_x: 2, max_y: 4, source: "item-4", },
      { min_x: -3, min_y: -4, max_x: 1, max_y: 4, source: "item-5", },
      { min_x: -1, min_y: -1, max_x: 3, max_y: 4, source: "item-6", },
      { min_x: -4, min_y: -3, max_x: 4, max_y: 1, source: "item-7", },
      { min_x: -1, min_y: -3, max_x: 0, max_y: 0, source: "item-8", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "58",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -4, max_x: -1, max_y: 3, source: "item-0", },
      { min_x: -2, min_y: -3, max_x: -1, max_y: 3, source: "item-1", },
      { min_x: -1, min_y: -3, max_x: 1, max_y: 4, source: "item-2", },
      { min_x: -4, min_y: -2, max_x: 2, max_y: 3, source: "item-3", },
      { min_x: 0, min_y: -4, max_x: 3, max_y: -2, source: "item-4", },
      { min_x: -1, min_y: 0, max_x: 4, max_y: 4, source: "item-5", },
      { min_x: -2, min_y: -2, max_x: 2, max_y: -1, source: "item-6", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "52",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: 3, max_x: 0, max_y: 4, source: "item-0", },
      { min_x: -4, min_y: -4, max_x: 1, max_y: 0, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "23",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: -4, max_x: 4, max_y: -2, source: "item-0", },
      { min_x: -4, min_y: -4, max_x: -3, max_y: 0, source: "item-1", },
      { min_x: -2, min_y: -4, max_x: 2, max_y: 0, source: "item-2", },
      { min_x: -1, min_y: -3, max_x: 1, max_y: 4, source: "item-3", },
      { min_x: -3, min_y: -4, max_x: -1, max_y: 2, source: "item-4", },
      { min_x: -4, min_y: -3, max_x: -1, max_y: 2, source: "item-5", },
      { min_x: -4, min_y: -3, max_x: 0, max_y: -2, source: "item-6", },
      { min_x: -4, min_y: 1, max_x: 3, max_y: 2, source: "item-7", },
      { min_x: -2, min_y: -3, max_x: 2, max_y: 4, source: "item-8", },
      { min_x: 0, min_y: -3, max_x: 4, max_y: -2, source: "item-9", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "49",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -4, max_x: 3, max_y: 4, source: "item-0", },
      { min_x: 2, min_y: -1, max_x: 3, max_y: 3, source: "item-1", },
      { min_x: -2, min_y: -3, max_x: 0, max_y: 0, source: "item-2", },
      { min_x: -3, min_y: 0, max_x: 1, max_y: 2, source: "item-3", },
      { min_x: 3, min_y: 1, max_x: 4, max_y: 2, source: "item-4", },
      { min_x: -1, min_y: -1, max_x: 2, max_y: 1, source: "item-5", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "40",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 2, min_y: -4, max_x: 4, max_y: -1, source: "item-0", },
    ]
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "6")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: -2, max_x: 2, max_y: 4, source: "item-0", },
      { min_x: -4, min_y: -3, max_x: 4, max_y: 1, source: "item-1", },
      { min_x: 1, min_y: 1, max_x: 2, max_y: 3, source: "item-2", },
      { min_x: -3, min_y: -1, max_x: -1, max_y: 3, source: "item-3", },
      { min_x: 1, min_y: -1, max_x: 2, max_y: 1, source: "item-4", },
      { min_x: -2, min_y: -2, max_x: 4, max_y: 4, source: "item-5", },
      { min_x: -2, min_y: -3, max_x: 2, max_y: 4, source: "item-6", },
      { min_x: -2, min_y: -1, max_x: 3, max_y: 2, source: "item-7", },
      { min_x: -2, min_y: -3, max_x: 1, max_y: -1, source: "item-8", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "52",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -1, max_x: 1, max_y: 2, source: "item-0", },
      { min_x: 3, min_y: -2, max_x: 4, max_y: -1, source: "item-1", },
      { min_x: 0, min_y: 0, max_x: 3, max_y: 2, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "17",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 3, min_y: 1, max_x: 4, max_y: 3, source: "item-0", },
      { min_x: -1, min_y: -1, max_x: 2, max_y: 0, source: "item-1", },
      { min_x: -4, min_y: 0, max_x: -3, max_y: 3, source: "item-2", },
      { min_x: -4, min_y: -2, max_x: -3, max_y: 3, source: "item-3", },
      { min_x: -3, min_y: -2, max_x: -1, max_y: 2, source: "item-4", },
      { min_x: 1, min_y: -1, max_x: 3, max_y: 1, source: "item-5", },
      { min_x: -4, min_y: -1, max_x: -1, max_y: 0, source: "item-6", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "21",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: -3, max_x: 2, max_y: 2, source: "item-0", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "10",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 3, min_y: 1, max_x: 4, max_y: 4, source: "item-0", },
      { min_x: -1, min_y: -4, max_x: 1, max_y: 3, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "17",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = []
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "0")
  }
  {
    let rectangles : Array[@gdsii.Rect] = []
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "0")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -2, min_y: -4, max_x: 1, max_y: 1, source: "item-0", },
      { min_x: -2, min_y: -4, max_x: 0, max_y: 3, source: "item-1", },
      { min_x: 1, min_y: -3, max_x: 4, max_y: -1, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "25",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: -1, max_x: 1, max_y: 3, source: "item-0", },
      { min_x: -3, min_y: 3, max_x: -2, max_y: 4, source: "item-1", },
      { min_x: -1, min_y: -4, max_x: 3, max_y: 3, source: "item-2", },
      { min_x: -1, min_y: -4, max_x: 4, max_y: 1, source: "item-3", },
      { min_x: -1, min_y: 1, max_x: 4, max_y: 4, source: "item-4", },
      { min_x: 2, min_y: -3, max_x: 3, max_y: 4, source: "item-5", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "53",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: 0, max_x: 0, max_y: 4, source: "item-0", },
      { min_x: 2, min_y: -4, max_x: 3, max_y: -3, source: "item-1", },
      { min_x: 2, min_y: -2, max_x: 3, max_y: 2, source: "item-2", },
      { min_x: -3, min_y: 2, max_x: 3, max_y: 4, source: "item-3", },
      { min_x: 0, min_y: -1, max_x: 4, max_y: 4, source: "item-4", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "34",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -1, max_x: 0, max_y: 0, source: "item-0", },
      { min_x: 2, min_y: 1, max_x: 3, max_y: 3, source: "item-1", },
    ]
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "3")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 1, min_y: -3, max_x: 2, max_y: 0, source: "item-0", },
      { min_x: 1, min_y: 0, max_x: 3, max_y: 1, source: "item-1", },
      { min_x: -3, min_y: -4, max_x: 1, max_y: 4, source: "item-2", },
      { min_x: 3, min_y: -4, max_x: 4, max_y: 0, source: "item-3", },
      { min_x: -3, min_y: 0, max_x: 2, max_y: 1, source: "item-4", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "41",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 3, min_y: -2, max_x: 4, max_y: 2, source: "item-0", },
      { min_x: -4, min_y: 0, max_x: 0, max_y: 2, source: "item-1", },
      { min_x: -4, min_y: 0, max_x: 0, max_y: 1, source: "item-2", },
      { min_x: 0, min_y: -4, max_x: 2, max_y: 2, source: "item-3", },
      { min_x: -3, min_y: -3, max_x: -1, max_y: 4, source: "item-4", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "34",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 3, min_y: 2, max_x: 4, max_y: 3, source: "item-0", },
      { min_x: 1, min_y: -1, max_x: 3, max_y: 0, source: "item-1", },
      { min_x: 0, min_y: 0, max_x: 3, max_y: 3, source: "item-2", },
      { min_x: -2, min_y: -3, max_x: 0, max_y: 2, source: "item-3", },
      { min_x: -4, min_y: 1, max_x: 2, max_y: 2, source: "item-4", },
      { min_x: 0, min_y: -1, max_x: 3, max_y: 3, source: "item-5", },
      { min_x: -1, min_y: -4, max_x: 1, max_y: 1, source: "item-6", },
      { min_x: 0, min_y: 1, max_x: 2, max_y: 3, source: "item-7", },
      { min_x: -4, min_y: -1, max_x: 4, max_y: 3, source: "item-8", },
      { min_x: -4, min_y: 2, max_x: -1, max_y: 4, source: "item-9", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "43",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: 3, max_x: -3, max_y: 4, source: "item-0", },
      { min_x: 3, min_y: 0, max_x: 4, max_y: 3, source: "item-1", },
    ]
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "4")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -2, min_y: -3, max_x: 2, max_y: -1, source: "item-0", },
      { min_x: -4, min_y: -4, max_x: -1, max_y: -1, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "15",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -2, min_y: -2, max_x: 3, max_y: -1, source: "item-0", },
      { min_x: -2, min_y: 1, max_x: -1, max_y: 3, source: "item-1", },
      { min_x: -2, min_y: -4, max_x: -1, max_y: -2, source: "item-2", },
      { min_x: -1, min_y: 3, max_x: 2, max_y: 4, source: "item-3", },
      { min_x: 0, min_y: 1, max_x: 1, max_y: 4, source: "item-4", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "14",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -2, min_y: -3, max_x: -1, max_y: 2, source: "item-0", },
      { min_x: -1, min_y: -4, max_x: 2, max_y: -1, source: "item-1", },
      { min_x: -1, min_y: -3, max_x: 1, max_y: 3, source: "item-2", },
      { min_x: 1, min_y: -3, max_x: 3, max_y: 4, source: "item-3", },
      { min_x: -4, min_y: -2, max_x: 3, max_y: 3, source: "item-4", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "45",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = []
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "0")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -4, max_x: 1, max_y: -3, source: "item-0", },
    ]
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "2")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 1, min_y: 0, max_x: 4, max_y: 2, source: "item-0", },
      { min_x: -4, min_y: -1, max_x: 1, max_y: 3, source: "item-1", },
      { min_x: 0, min_y: -4, max_x: 1, max_y: -2, source: "item-2", },
      { min_x: 2, min_y: 2, max_x: 4, max_y: 4, source: "item-3", },
      { min_x: -4, min_y: 1, max_x: 2, max_y: 2, source: "item-4", },
      { min_x: 2, min_y: -2, max_x: 4, max_y: 1, source: "item-5", },
      { min_x: -4, min_y: -3, max_x: 1, max_y: -1, source: "item-6", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "45",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -1, max_x: 3, max_y: 1, source: "item-0", },
      { min_x: 0, min_y: -1, max_x: 3, max_y: 4, source: "item-1", },
      { min_x: -2, min_y: 0, max_x: 3, max_y: 3, source: "item-2", },
      { min_x: 1, min_y: 1, max_x: 3, max_y: 2, source: "item-3", },
      { min_x: -3, min_y: -3, max_x: 4, max_y: 2, source: "item-4", },
      { min_x: -2, min_y: 3, max_x: -1, max_y: 4, source: "item-5", },
      { min_x: -2, min_y: -4, max_x: 1, max_y: -1, source: "item-6", },
      { min_x: -3, min_y: -2, max_x: -2, max_y: -1, source: "item-7", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "47",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: -4, max_x: 3, max_y: -2, source: "item-0", },
      { min_x: 0, min_y: -4, max_x: 4, max_y: 4, source: "item-1", },
      { min_x: -3, min_y: 2, max_x: -2, max_y: 3, source: "item-2", },
      { min_x: 2, min_y: -4, max_x: 4, max_y: 4, source: "item-3", },
      { min_x: -1, min_y: -4, max_x: 2, max_y: -2, source: "item-4", },
      { min_x: -2, min_y: 1, max_x: -1, max_y: 2, source: "item-5", },
      { min_x: 0, min_y: -4, max_x: 4, max_y: -2, source: "item-6", },
      { min_x: -3, min_y: -1, max_x: -1, max_y: 3, source: "item-7", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "48",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -4, max_x: 2, max_y: -1, source: "item-0", },
      { min_x: 0, min_y: -2, max_x: 3, max_y: 3, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "22",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -4, max_x: 0, max_y: 4, source: "item-0", },
      { min_x: -2, min_y: -4, max_x: 2, max_y: 4, source: "item-1", },
      { min_x: -4, min_y: -2, max_x: -2, max_y: 3, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "42",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -3, max_x: -2, max_y: 1, source: "item-0", },
      { min_x: 0, min_y: -2, max_x: 3, max_y: 3, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "19",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -2, min_y: 2, max_x: 4, max_y: 4, source: "item-0", },
      { min_x: 0, min_y: 0, max_x: 3, max_y: 1, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "15",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -4, max_x: 3, max_y: 1, source: "item-0", },
      { min_x: -4, min_y: 0, max_x: 4, max_y: 2, source: "item-1", },
      { min_x: -4, min_y: 1, max_x: 2, max_y: 4, source: "item-2", },
      { min_x: 3, min_y: -4, max_x: 4, max_y: 4, source: "item-3", },
      { min_x: -2, min_y: -1, max_x: 0, max_y: 0, source: "item-4", },
      { min_x: -3, min_y: -3, max_x: 4, max_y: -2, source: "item-5", },
      { min_x: -1, min_y: 1, max_x: 4, max_y: 4, source: "item-6", },
      { min_x: -1, min_y: -3, max_x: 0, max_y: 1, source: "item-7", },
      { min_x: -3, min_y: -3, max_x: 3, max_y: 1, source: "item-8", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "60",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: 1, max_x: -2, max_y: 2, source: "item-0", },
      { min_x: -4, min_y: -3, max_x: 4, max_y: 2, source: "item-1", },
      { min_x: -3, min_y: 0, max_x: -2, max_y: 2, source: "item-2", },
      { min_x: -3, min_y: -3, max_x: 0, max_y: 1, source: "item-3", },
      { min_x: -4, min_y: -1, max_x: -2, max_y: 4, source: "item-4", },
      { min_x: -2, min_y: -2, max_x: 4, max_y: 1, source: "item-5", },
      { min_x: -1, min_y: -2, max_x: 0, max_y: 1, source: "item-6", },
      { min_x: 3, min_y: -4, max_x: 4, max_y: 0, source: "item-7", },
      { min_x: -3, min_y: -4, max_x: 2, max_y: 0, source: "item-8", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "50",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -3, max_x: 1, max_y: 3, source: "item-0", },
      { min_x: 3, min_y: -1, max_x: 4, max_y: 1, source: "item-1", },
      { min_x: 0, min_y: 1, max_x: 3, max_y: 3, source: "item-2", },
      { min_x: -4, min_y: -2, max_x: 3, max_y: 0, source: "item-3", },
      { min_x: -2, min_y: 0, max_x: -1, max_y: 3, source: "item-4", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "36",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -3, max_x: 4, max_y: 3, source: "item-0", },
      { min_x: -2, min_y: 1, max_x: 1, max_y: 2, source: "item-1", },
      { min_x: -3, min_y: -4, max_x: -1, max_y: -2, source: "item-2", },
      { min_x: -2, min_y: -4, max_x: 0, max_y: 2, source: "item-3", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "39",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 0, max_x: 2, max_y: 2, source: "item-0", },
      { min_x: -4, min_y: -4, max_x: -3, max_y: -2, source: "item-1", },
      { min_x: -4, min_y: -3, max_x: 4, max_y: 2, source: "item-2", },
      { min_x: -2, min_y: -3, max_x: 2, max_y: 1, source: "item-3", },
      { min_x: -2, min_y: -1, max_x: 4, max_y: 0, source: "item-4", },
      { min_x: -3, min_y: -1, max_x: 2, max_y: 3, source: "item-5", },
      { min_x: -2, min_y: 2, max_x: 2, max_y: 4, source: "item-6", },
      { min_x: -4, min_y: 0, max_x: 3, max_y: 4, source: "item-7", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "55",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: -3, max_x: -3, max_y: 4, source: "item-0", },
      { min_x: -4, min_y: 1, max_x: 1, max_y: 2, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "11",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: 2, max_x: 3, max_y: 4, source: "item-0", },
      { min_x: -4, min_y: -1, max_x: 4, max_y: 0, source: "item-1", },
      { min_x: -2, min_y: 0, max_x: 4, max_y: 3, source: "item-2", },
      { min_x: -4, min_y: -3, max_x: 4, max_y: -2, source: "item-3", },
      { min_x: -2, min_y: 2, max_x: 3, max_y: 4, source: "item-4", },
      { min_x: -3, min_y: 3, max_x: 3, max_y: 4, source: "item-5", },
      { min_x: -2, min_y: 0, max_x: 4, max_y: 1, source: "item-6", },
      { min_x: -4, min_y: -2, max_x: 0, max_y: 1, source: "item-7", },
      { min_x: -1, min_y: -1, max_x: 4, max_y: 3, source: "item-8", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "47",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 3, max_x: 2, max_y: 4, source: "item-0", },
      { min_x: 1, min_y: -3, max_x: 4, max_y: -2, source: "item-1", },
      { min_x: -3, min_y: -3, max_x: -1, max_y: 3, source: "item-2", },
      { min_x: -4, min_y: -2, max_x: -2, max_y: 0, source: "item-3", },
      { min_x: -4, min_y: 2, max_x: 2, max_y: 3, source: "item-4", },
      { min_x: -1, min_y: -4, max_x: 4, max_y: 4, source: "item-5", },
      { min_x: 0, min_y: -3, max_x: 4, max_y: -1, source: "item-6", },
      { min_x: -2, min_y: -3, max_x: 3, max_y: 3, source: "item-7", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "55",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -2, min_y: 2, max_x: 0, max_y: 3, source: "item-0", },
    ]
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "2")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -4, max_x: 1, max_y: -3, source: "item-0", },
      { min_x: -4, min_y: -4, max_x: 2, max_y: 3, source: "item-1", },
      { min_x: 2, min_y: 2, max_x: 4, max_y: 4, source: "item-2", },
      { min_x: 1, min_y: -3, max_x: 4, max_y: -2, source: "item-3", },
      { min_x: -2, min_y: -3, max_x: -1, max_y: 3, source: "item-4", },
      { min_x: -4, min_y: 2, max_x: -2, max_y: 3, source: "item-5", },
      { min_x: -3, min_y: -3, max_x: -1, max_y: -2, source: "item-6", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "48",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = []
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "0")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: -4, max_x: 0, max_y: 0, source: "item-0", },
      { min_x: -4, min_y: -4, max_x: 2, max_y: 0, source: "item-1", },
      { min_x: -2, min_y: -2, max_x: -1, max_y: 0, source: "item-2", },
      { min_x: -3, min_y: -3, max_x: -1, max_y: 1, source: "item-3", },
      { min_x: 1, min_y: -3, max_x: 4, max_y: 2, source: "item-4", },
      { min_x: -2, min_y: -1, max_x: 1, max_y: 3, source: "item-5", },
      { min_x: -2, min_y: -3, max_x: 2, max_y: 4, source: "item-6", },
      { min_x: 1, min_y: -4, max_x: 3, max_y: -1, source: "item-7", },
      { min_x: -3, min_y: -3, max_x: -2, max_y: 1, source: "item-8", },
      { min_x: -3, min_y: 1, max_x: -1, max_y: 3, source: "item-9", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "54",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -2, max_x: 2, max_y: 1, source: "item-0", },
      { min_x: 0, min_y: -3, max_x: 4, max_y: 2, source: "item-1", },
      { min_x: 0, min_y: -4, max_x: 1, max_y: 4, source: "item-2", },
      { min_x: -3, min_y: -2, max_x: 0, max_y: 4, source: "item-3", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "41",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: -4, max_x: 4, max_y: 3, source: "item-0", },
      { min_x: -4, min_y: 2, max_x: 1, max_y: 3, source: "item-1", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "56",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: -2, max_x: 2, max_y: -1, source: "item-0", },
      { min_x: -3, min_y: -1, max_x: -1, max_y: 1, source: "item-1", },
    ]
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "6")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -4, max_x: 4, max_y: 4, source: "item-0", },
      { min_x: 1, min_y: -1, max_x: 3, max_y: 1, source: "item-1", },
      { min_x: -1, min_y: 2, max_x: 3, max_y: 4, source: "item-2", },
      { min_x: -1, min_y: -3, max_x: 1, max_y: -1, source: "item-3", },
      { min_x: -4, min_y: -1, max_x: 3, max_y: 3, source: "item-4", },
      { min_x: -3, min_y: 0, max_x: 3, max_y: 2, source: "item-5", },
      { min_x: 1, min_y: -3, max_x: 4, max_y: 3, source: "item-6", },
      { min_x: -1, min_y: 1, max_x: 4, max_y: 2, source: "item-7", },
      { min_x: -4, min_y: -4, max_x: 0, max_y: -3, source: "item-8", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "61",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: -3, max_x: 4, max_y: -2, source: "item-0", },
      { min_x: 1, min_y: -4, max_x: 3, max_y: 4, source: "item-1", },
      { min_x: -3, min_y: -4, max_x: -2, max_y: 1, source: "item-2", },
      { min_x: 3, min_y: -3, max_x: 4, max_y: 4, source: "item-3", },
      { min_x: -3, min_y: -1, max_x: 0, max_y: 2, source: "item-4", },
      { min_x: -4, min_y: -3, max_x: 4, max_y: -1, source: "item-5", },
      { min_x: 3, min_y: -2, max_x: 4, max_y: 0, source: "item-6", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "43",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: -4, max_x: 3, max_y: 4, source: "item-0", },
      { min_x: 2, min_y: -4, max_x: 3, max_y: 3, source: "item-1", },
      { min_x: -2, min_y: 1, max_x: 1, max_y: 3, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "28",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: -4, max_x: 0, max_y: -3, source: "item-0", },
      { min_x: 2, min_y: -1, max_x: 4, max_y: 2, source: "item-1", },
      { min_x: -4, min_y: -3, max_x: 3, max_y: -1, source: "item-2", },
      { min_x: -2, min_y: -3, max_x: 4, max_y: 2, source: "item-3", },
      { min_x: 1, min_y: 3, max_x: 3, max_y: 4, source: "item-4", },
      { min_x: -3, min_y: -2, max_x: -1, max_y: 1, source: "item-5", },
      { min_x: -2, min_y: -2, max_x: 2, max_y: 0, source: "item-6", },
      { min_x: -2, min_y: -2, max_x: 0, max_y: -1, source: "item-7", },
      { min_x: -4, min_y: -3, max_x: 4, max_y: -2, source: "item-8", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "42",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -4, max_x: 3, max_y: 3, source: "item-0", },
      { min_x: 2, min_y: 0, max_x: 4, max_y: 4, source: "item-1", },
      { min_x: -4, min_y: -2, max_x: -1, max_y: 1, source: "item-2", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "50",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -3, min_y: -4, max_x: 4, max_y: -2, source: "item-0", },
      { min_x: -4, min_y: -4, max_x: -2, max_y: 0, source: "item-1", },
      { min_x: -4, min_y: 3, max_x: 3, max_y: 4, source: "item-2", },
      { min_x: -4, min_y: 0, max_x: 4, max_y: 4, source: "item-3", },
      { min_x: -4, min_y: -3, max_x: -3, max_y: 3, source: "item-4", },
      { min_x: -3, min_y: -4, max_x: 3, max_y: -2, source: "item-5", },
      { min_x: 2, min_y: 1, max_x: 4, max_y: 4, source: "item-6", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "52",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: -4, max_x: 1, max_y: -3, source: "item-0", },
      { min_x: 1, min_y: 2, max_x: 4, max_y: 3, source: "item-1", },
      { min_x: -3, min_y: -4, max_x: 0, max_y: -1, source: "item-2", },
      { min_x: 0, min_y: -3, max_x: 4, max_y: 2, source: "item-3", },
      { min_x: -3, min_y: -4, max_x: -1, max_y: 2, source: "item-4", },
      { min_x: -4, min_y: -3, max_x: 0, max_y: -2, source: "item-5", },
      { min_x: -4, min_y: -3, max_x: 3, max_y: -1, source: "item-6", },
      { min_x: -4, min_y: -3, max_x: -1, max_y: 1, source: "item-7", },
      { min_x: -4, min_y: 0, max_x: 0, max_y: 4, source: "item-8", },
      { min_x: 0, min_y: 1, max_x: 1, max_y: 3, source: "item-9", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "55",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: -1, max_x: 1, max_y: 1, source: "item-0", },
      { min_x: -2, min_y: -1, max_x: 3, max_y: 3, source: "item-1", },
      { min_x: -2, min_y: -4, max_x: 4, max_y: 2, source: "item-2", },
      { min_x: 0, min_y: 2, max_x: 2, max_y: 4, source: "item-3", },
      { min_x: -1, min_y: -1, max_x: 1, max_y: 1, source: "item-4", },
      { min_x: -2, min_y: 1, max_x: 3, max_y: 3, source: "item-5", },
      { min_x: 2, min_y: 2, max_x: 3, max_y: 3, source: "item-6", },
      { min_x: -1, min_y: -1, max_x: 2, max_y: 2, source: "item-7", },
      { min_x: -4, min_y: 2, max_x: 4, max_y: 3, source: "item-8", },
      { min_x: -3, min_y: -1, max_x: 3, max_y: 4, source: "item-9", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "53",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 0, min_y: 0, max_x: 4, max_y: 3, source: "item-0", },
      { min_x: -3, min_y: 2, max_x: -2, max_y: 3, source: "item-1", },
      { min_x: 0, min_y: -4, max_x: 2, max_y: 4, source: "item-2", },
      { min_x: -3, min_y: 0, max_x: 3, max_y: 1, source: "item-3", },
      { min_x: -1, min_y: -3, max_x: 0, max_y: 1, source: "item-4", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "29",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -1, min_y: -4, max_x: 3, max_y: -1, source: "item-0", },
      { min_x: -2, min_y: -4, max_x: 3, max_y: 4, source: "item-1", },
      { min_x: -4, min_y: -2, max_x: 1, max_y: 1, source: "item-2", },
      { min_x: -4, min_y: -2, max_x: -1, max_y: 1, source: "item-3", },
      { min_x: -3, min_y: -1, max_x: -1, max_y: 0, source: "item-4", },
      { min_x: -1, min_y: 2, max_x: 2, max_y: 4, source: "item-5", },
      { min_x: 3, min_y: -2, max_x: 4, max_y: 1, source: "item-6", },
      { min_x: -4, min_y: 3, max_x: 4, max_y: 4, source: "item-7", },
      { min_x: -4, min_y: 2, max_x: -2, max_y: 4, source: "item-8", },
      { min_x: 0, min_y: -2, max_x: 1, max_y: 2, source: "item-9", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "54",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: 2, min_y: -2, max_x: 4, max_y: 0, source: "item-0", },
    ]
    assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "4")
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      { min_x: -4, min_y: 2, max_x: 4, max_y: 3, source: "item-0", },
      { min_x: 1, min_y: -4, max_x: 3, max_y: 3, source: "item-1", },
      { min_x: -1, min_y: -1, max_x: 0, max_y: 4, source: "item-2", },
      { min_x: -3, min_y: -1, max_x: 4, max_y: 2, source: "item-3", },
      { min_x: 0, min_y: -1, max_x: 3, max_y: 1, source: "item-4", },
      { min_x: -3, min_y: -3, max_x: 3, max_y: 1, source: "item-5", },
      { min_x: -3, min_y: -4, max_x: -2, max_y: -1, source: "item-6", },
      { min_x: 0, min_y: -4, max_x: 4, max_y: -1, source: "item-7", },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "49",
    )
  }
  let rectangles : Array[@gdsii.Rect] = [
    { min_x: -4, min_y: -1, max_x: -1, max_y: 0, source: "item-0", },
    { min_x: -4, min_y: 2, max_x: 4, max_y: 3, source: "item-1", },
    { min_x: 2, min_y: -4, max_x: 3, max_y: -1, source: "item-2", },
    { min_x: -4, min_y: -2, max_x: 3, max_y: 3, source: "item-3", },
    { min_x: -3, min_y: -3, max_x: 2, max_y: 1, source: "item-4", },
    { min_x: -2, min_y: -2, max_x: 1, max_y: 4, source: "item-5", },
    { min_x: 1, min_y: -1, max_x: 3, max_y: 1, source: "item-6", },
    { min_x: -3, min_y: -2, max_x: 4, max_y: 4, source: "item-7", },
    { min_x: 1, min_y: -4, max_x: 3, max_y: 1, source: "item-8", },
  ]
  assert_eq(@gdsii.rectangle_union_area(rectangles).unwrap().to_string(), "55")
}

///|
test "rectangle union area exact unsigned64 and unsafe JSON-number range" {
  {
    let rectangles : Array[@gdsii.Rect] = [
      {
        min_x: -2147483648,
        min_y: -2147483648,
        max_x: 2147483647,
        max_y: 2147483647,
        source: "item-0",
      },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "18446744065119617025",
    )
  }
  {
    let rectangles : Array[@gdsii.Rect] = [
      {
        min_x: 0,
        min_y: 0,
        max_x: 100000001,
        max_y: 100000003,
        source: "item-0",
      },
    ]
    assert_eq(
      @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
      "10000000400000003",
    )
  }
  let rectangles : Array[@gdsii.Rect] = [
    {
      min_x: -2147483648,
      min_y: -2147483648,
      max_x: 2147483647,
      max_y: 2147483647,
      source: "item-0",
    },
    {
      min_x: -2147483648,
      min_y: -2147483648,
      max_x: 2147483647,
      max_y: 2147483647,
      source: "item-1",
    },
    { min_x: -1, min_y: -1, max_x: 1, max_y: 1, source: "item-2", },
  ]
  assert_eq(
    @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
    "18446744065119617025",
  )
}

///|
test "rectangle union area leaves caller order and labels untouched" {
  let a : @gdsii.Rect = { min_x: 0, min_y: 0, max_x: 4, max_y: 4, source: "a", }
  let b : @gdsii.Rect = { min_x: 2, min_y: 0, max_x: 6, max_y: 4, source: "b", }
  let original = [b, a, b]
  let saved = original.copy()
  assert_eq(@gdsii.rectangle_union_area(original).unwrap(), 24UL)
  assert_eq(original, saved)
  let renamed : @gdsii.Rect = {
    min_x: 0,
    min_y: 0,
    max_x: 4,
    max_y: 4,
    source: "different label",
  }
  assert_eq(@gdsii.rectangle_union_area([renamed, b]).unwrap(), 24UL)
}

///|
test "rectangle union area rejects invalid last dimensions without mutation" {
  let valid : @gdsii.Rect = {
    min_x: 0,
    min_y: 0,
    max_x: 4,
    max_y: 4,
    source: "valid",
  }
  let invalid : Array[@gdsii.Rect] = [
    { min_x: 0, min_y: 0, max_x: 0, max_y: 1, source: "invalid", },
    { min_x: 0, min_y: 0, max_x: 1, max_y: 0, source: "invalid", },
    { min_x: 1, min_y: 0, max_x: 0, max_y: 1, source: "invalid", },
    { min_x: 0, min_y: 1, max_x: 1, max_y: 0, source: "invalid", },
  ]
  for bad in invalid {
    let rectangles = [valid, bad]
    let saved = rectangles.copy()
    guard @gdsii.rectangle_union_area(rectangles)
      is Err(@gdsii.InvalidGeometry(_)) else {
      fail("nonpositive dimensions must reject the whole measurement")
    }
    assert_eq(rectangles, saved)
  }
}

///|
test "rectangle union area10000 disjoint stripes exact arithmetic oracle" {
  let rectangles : Array[@gdsii.Rect] = [
    for i in 0..<10000 => {
      {
        min_x: i * 2,
        min_y: -(i % 127),
        max_x: i * 2 + 1,
        max_y: 1000 + i % 127,
        source: "stripe",
      }
    }
  ]
  assert_eq(
    @gdsii.rectangle_union_area(rectangles).unwrap().to_string(),
    "11256898",
  )
}
