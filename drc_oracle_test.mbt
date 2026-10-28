///|
test "independent DRC touch-overlap-corner" {
  let rects : Array[@gdsii.Rect] = [
    { min_x: 0, min_y: 0, max_x: 10, max_y: 10, source: "box-0", },
    { min_x: 10, min_y: 0, max_x: 20, max_y: 10, source: "box-1", },
    { min_x: 5, min_y: 5, max_x: 15, max_y: 15, source: "box-2", },
    { min_x: 21, min_y: 11, max_x: 22, max_y: 12, source: "box-3", },
  ]
  let report = @gdsii.check_manhattan_drc(rects, 3, 2).unwrap()
  let pairs = []
  let widths = []
  for v in report.violations {
    match v {
      @gdsii.MinimumWidth(id, _) => widths.push(id)
      @gdsii.MinimumSpacing(a, b, d) => {
        pairs.push((a, b))
        assert_true(d >= 0.0 && d < 2.0)
      }
    }
  }
  pairs.sort_by(fn(a, b) {
    let c = a.0.compare(b.0)
    if c == 0 {
      a.1.compare(b.1)
    } else {
      c
    }
  })
  let expected_pairs : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3)]
  let expected_widths : Array[Int] = [3]
  assert_eq(pairs, expected_pairs)
  assert_eq(widths, expected_widths)
  assert_true(report.candidates >= pairs.length().to_int64())
}

///|
test "independent DRC dense" {
  let rects : Array[@gdsii.Rect] = [
    { min_x: 0, min_y: 0, max_x: 1, max_y: 1, source: "box-0", },
    { min_x: 0, min_y: 1, max_x: 1, max_y: 2, source: "box-1", },
    { min_x: 0, min_y: 2, max_x: 1, max_y: 3, source: "box-2", },
    { min_x: 0, min_y: 3, max_x: 1, max_y: 4, source: "box-3", },
    { min_x: 0, min_y: 4, max_x: 1, max_y: 5, source: "box-4", },
    { min_x: 0, min_y: 5, max_x: 1, max_y: 6, source: "box-5", },
    { min_x: 0, min_y: 6, max_x: 1, max_y: 7, source: "box-6", },
    { min_x: 0, min_y: 7, max_x: 1, max_y: 8, source: "box-7", },
    { min_x: 0, min_y: 8, max_x: 1, max_y: 9, source: "box-8", },
    { min_x: 0, min_y: 9, max_x: 1, max_y: 10, source: "box-9", },
    { min_x: 0, min_y: 10, max_x: 1, max_y: 11, source: "box-10", },
    { min_x: 0, min_y: 11, max_x: 1, max_y: 12, source: "box-11", },
    { min_x: 0, min_y: 12, max_x: 1, max_y: 13, source: "box-12", },
    { min_x: 0, min_y: 13, max_x: 1, max_y: 14, source: "box-13", },
    { min_x: 0, min_y: 14, max_x: 1, max_y: 15, source: "box-14", },
    { min_x: 0, min_y: 15, max_x: 1, max_y: 16, source: "box-15", },
    { min_x: 0, min_y: 16, max_x: 1, max_y: 17, source: "box-16", },
    { min_x: 0, min_y: 17, max_x: 1, max_y: 18, source: "box-17", },
    { min_x: 0, min_y: 18, max_x: 1, max_y: 19, source: "box-18", },
    { min_x: 0, min_y: 19, max_x: 1, max_y: 20, source: "box-19", },
  ]
  let report = @gdsii.check_manhattan_drc(rects, 2, 30).unwrap()
  let pairs = []
  let widths = []
  for v in report.violations {
    match v {
      @gdsii.MinimumWidth(id, _) => widths.push(id)
      @gdsii.MinimumSpacing(a, b, d) => {
        pairs.push((a, b))
        assert_true(d >= 0.0 && d < 30.0)
      }
    }
  }
  pairs.sort_by(fn(a, b) {
    let c = a.0.compare(b.0)
    if c == 0 {
      a.1.compare(b.1)
    } else {
      c
    }
  })
  let expected_pairs : Array[(Int, Int)] = [
    (0, 1),
    (0, 2),
    (0, 3),
    (0, 4),
    (0, 5),
    (0, 6),
    (0, 7),
    (0, 8),
    (0, 9),
    (0, 10),
    (0, 11),
    (0, 12),
    (0, 13),
    (0, 14),
    (0, 15),
    (0, 16),
    (0, 17),
    (0, 18),
    (0, 19),
    (1, 2),
    (1, 3),
    (1, 4),
    (1, 5),
    (1, 6),
    (1, 7),
    (1, 8),
    (1, 9),
    (1, 10),
    (1, 11),
    (1, 12),
    (1, 13),
    (1, 14),
    (1, 15),
    (1, 16),
    (1, 17),
    (1, 18),
    (1, 19),
    (2, 3),
    (2, 4),
    (2, 5),
    (2, 6),
    (2, 7),
    (2, 8),
    (2, 9),
    (2, 10),
    (2, 11),
    (2, 12),
    (2, 13),
    (2, 14),
    (2, 15),
    (2, 16),
    (2, 17),
    (2, 18),
    (2, 19),
    (3, 4),
    (3, 5),
    (3, 6),
    (3, 7),
    (3, 8),
    (3, 9),
    (3, 10),
    (3, 11),
    (3, 12),
    (3, 13),
    (3, 14),
    (3, 15),
    (3, 16),
    (3, 17),
    (3, 18),
    (3, 19),
    (4, 5),
    (4, 6),
    (4, 7),
    (4, 8),
    (4, 9),
    (4, 10),
    (4, 11),
    (4, 12),
    (4, 13),
    (4, 14),
    (4, 15),
    (4, 16),
    (4, 17),
    (4, 18),
    (4, 19),
    (5, 6),
    (5, 7),
    (5, 8),
    (5, 9),
    (5, 10),
    (5, 11),
    (5, 12),
    (5, 13),
    (5, 14),
    (5, 15),
    (5, 16),
    (5, 17),
    (5, 18),
    (5, 19),
    (6, 7),
    (6, 8),
    (6, 9),
    (6, 10),
    (6, 11),
    (6, 12),
    (6, 13),
    (6, 14),
    (6, 15),
    (6, 16),
    (6, 17),
    (6, 18),
    (6, 19),
    (7, 8),
    (7, 9),
    (7, 10),
    (7, 11),
    (7, 12),
    (7, 13),
    (7, 14),
    (7, 15),
    (7, 16),
    (7, 17),
    (7, 18),
    (7, 19),
    (8, 9),
    (8, 10),
    (8, 11),
    (8, 12),
    (8, 13),
    (8, 14),
    (8, 15),
    (8, 16),
    (8, 17),
    (8, 18),
    (8, 19),
    (9, 10),
    (9, 11),
    (9, 12),
    (9, 13),
    (9, 14),
    (9, 15),
    (9, 16),
    (9, 17),
    (9, 18),
    (9, 19),
    (10, 11),
    (10, 12),
    (10, 13),
    (10, 14),
    (10, 15),
    (10, 16),
    (10, 17),
    (10, 18),
    (10, 19),
    (11, 12),
    (11, 13),
    (11, 14),
    (11, 15),
    (11, 16),
    (11, 17),
    (11, 18),
    (11, 19),
    (12, 13),
    (12, 14),
    (12, 15),
    (12, 16),
    (12, 17),
    (12, 18),
    (12, 19),
    (13, 14),
    (13, 15),
    (13, 16),
    (13, 17),
    (13, 18),
    (13, 19),
    (14, 15),
    (14, 16),
    (14, 17),
    (14, 18),
    (14, 19),
    (15, 16),
    (15, 17),
    (15, 18),
    (15, 19),
    (16, 17),
    (16, 18),
    (16, 19),
    (17, 18),
    (17, 19),
    (18, 19),
  ]
  let expected_widths : Array[Int] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  ]
  assert_eq(pairs, expected_pairs)
  assert_eq(widths, expected_widths)
  assert_true(report.candidates >= pairs.length().to_int64())
}

///|
test "independent DRC sparse" {
  let rects : Array[@gdsii.Rect] = [
    { min_x: 0, min_y: 0, max_x: 20, max_y: 3, source: "box-0", },
    { min_x: 0, min_y: 100, max_x: 20, max_y: 103, source: "box-1", },
    { min_x: 0, min_y: 200, max_x: 20, max_y: 203, source: "box-2", },
    { min_x: 0, min_y: 300, max_x: 20, max_y: 303, source: "box-3", },
    { min_x: 0, min_y: 400, max_x: 20, max_y: 403, source: "box-4", },
    { min_x: 0, min_y: 500, max_x: 20, max_y: 503, source: "box-5", },
    { min_x: 0, min_y: 600, max_x: 20, max_y: 603, source: "box-6", },
    { min_x: 0, min_y: 700, max_x: 20, max_y: 703, source: "box-7", },
    { min_x: 0, min_y: 800, max_x: 20, max_y: 803, source: "box-8", },
    { min_x: 0, min_y: 900, max_x: 20, max_y: 903, source: "box-9", },
    { min_x: 0, min_y: 1000, max_x: 20, max_y: 1003, source: "box-10", },
    { min_x: 0, min_y: 1100, max_x: 20, max_y: 1103, source: "box-11", },
    { min_x: 0, min_y: 1200, max_x: 20, max_y: 1203, source: "box-12", },
    { min_x: 0, min_y: 1300, max_x: 20, max_y: 1303, source: "box-13", },
    { min_x: 0, min_y: 1400, max_x: 20, max_y: 1403, source: "box-14", },
    { min_x: 0, min_y: 1500, max_x: 20, max_y: 1503, source: "box-15", },
    { min_x: 0, min_y: 1600, max_x: 20, max_y: 1603, source: "box-16", },
    { min_x: 0, min_y: 1700, max_x: 20, max_y: 1703, source: "box-17", },
    { min_x: 0, min_y: 1800, max_x: 20, max_y: 1803, source: "box-18", },
    { min_x: 0, min_y: 1900, max_x: 20, max_y: 1903, source: "box-19", },
    { min_x: 0, min_y: 2000, max_x: 20, max_y: 2003, source: "box-20", },
    { min_x: 0, min_y: 2100, max_x: 20, max_y: 2103, source: "box-21", },
    { min_x: 0, min_y: 2200, max_x: 20, max_y: 2203, source: "box-22", },
    { min_x: 0, min_y: 2300, max_x: 20, max_y: 2303, source: "box-23", },
    { min_x: 0, min_y: 2400, max_x: 20, max_y: 2403, source: "box-24", },
    { min_x: 0, min_y: 2500, max_x: 20, max_y: 2503, source: "box-25", },
    { min_x: 0, min_y: 2600, max_x: 20, max_y: 2603, source: "box-26", },
    { min_x: 0, min_y: 2700, max_x: 20, max_y: 2703, source: "box-27", },
    { min_x: 0, min_y: 2800, max_x: 20, max_y: 2803, source: "box-28", },
    { min_x: 0, min_y: 2900, max_x: 20, max_y: 2903, source: "box-29", },
    { min_x: 0, min_y: 3000, max_x: 20, max_y: 3003, source: "box-30", },
    { min_x: 0, min_y: 3100, max_x: 20, max_y: 3103, source: "box-31", },
    { min_x: 0, min_y: 3200, max_x: 20, max_y: 3203, source: "box-32", },
    { min_x: 0, min_y: 3300, max_x: 20, max_y: 3303, source: "box-33", },
    { min_x: 0, min_y: 3400, max_x: 20, max_y: 3403, source: "box-34", },
    { min_x: 0, min_y: 3500, max_x: 20, max_y: 3503, source: "box-35", },
    { min_x: 0, min_y: 3600, max_x: 20, max_y: 3603, source: "box-36", },
    { min_x: 0, min_y: 3700, max_x: 20, max_y: 3703, source: "box-37", },
    { min_x: 0, min_y: 3800, max_x: 20, max_y: 3803, source: "box-38", },
    { min_x: 0, min_y: 3900, max_x: 20, max_y: 3903, source: "box-39", },
    { min_x: 0, min_y: 4000, max_x: 20, max_y: 4003, source: "box-40", },
    { min_x: 0, min_y: 4100, max_x: 20, max_y: 4103, source: "box-41", },
    { min_x: 0, min_y: 4200, max_x: 20, max_y: 4203, source: "box-42", },
    { min_x: 0, min_y: 4300, max_x: 20, max_y: 4303, source: "box-43", },
    { min_x: 0, min_y: 4400, max_x: 20, max_y: 4403, source: "box-44", },
    { min_x: 0, min_y: 4500, max_x: 20, max_y: 4503, source: "box-45", },
    { min_x: 0, min_y: 4600, max_x: 20, max_y: 4603, source: "box-46", },
    { min_x: 0, min_y: 4700, max_x: 20, max_y: 4703, source: "box-47", },
    { min_x: 0, min_y: 4800, max_x: 20, max_y: 4803, source: "box-48", },
    { min_x: 0, min_y: 4900, max_x: 20, max_y: 4903, source: "box-49", },
    { min_x: 0, min_y: 5000, max_x: 20, max_y: 5003, source: "box-50", },
    { min_x: 0, min_y: 5100, max_x: 20, max_y: 5103, source: "box-51", },
    { min_x: 0, min_y: 5200, max_x: 20, max_y: 5203, source: "box-52", },
    { min_x: 0, min_y: 5300, max_x: 20, max_y: 5303, source: "box-53", },
    { min_x: 0, min_y: 5400, max_x: 20, max_y: 5403, source: "box-54", },
    { min_x: 0, min_y: 5500, max_x: 20, max_y: 5503, source: "box-55", },
    { min_x: 0, min_y: 5600, max_x: 20, max_y: 5603, source: "box-56", },
    { min_x: 0, min_y: 5700, max_x: 20, max_y: 5703, source: "box-57", },
    { min_x: 0, min_y: 5800, max_x: 20, max_y: 5803, source: "box-58", },
    { min_x: 0, min_y: 5900, max_x: 20, max_y: 5903, source: "box-59", },
    { min_x: 0, min_y: 6000, max_x: 20, max_y: 6003, source: "box-60", },
    { min_x: 0, min_y: 6100, max_x: 20, max_y: 6103, source: "box-61", },
    { min_x: 0, min_y: 6200, max_x: 20, max_y: 6203, source: "box-62", },
    { min_x: 0, min_y: 6300, max_x: 20, max_y: 6303, source: "box-63", },
    { min_x: 0, min_y: 6400, max_x: 20, max_y: 6403, source: "box-64", },
    { min_x: 0, min_y: 6500, max_x: 20, max_y: 6503, source: "box-65", },
    { min_x: 0, min_y: 6600, max_x: 20, max_y: 6603, source: "box-66", },
    { min_x: 0, min_y: 6700, max_x: 20, max_y: 6703, source: "box-67", },
    { min_x: 0, min_y: 6800, max_x: 20, max_y: 6803, source: "box-68", },
    { min_x: 0, min_y: 6900, max_x: 20, max_y: 6903, source: "box-69", },
    { min_x: 0, min_y: 7000, max_x: 20, max_y: 7003, source: "box-70", },
    { min_x: 0, min_y: 7100, max_x: 20, max_y: 7103, source: "box-71", },
    { min_x: 0, min_y: 7200, max_x: 20, max_y: 7203, source: "box-72", },
    { min_x: 0, min_y: 7300, max_x: 20, max_y: 7303, source: "box-73", },
    { min_x: 0, min_y: 7400, max_x: 20, max_y: 7403, source: "box-74", },
    { min_x: 0, min_y: 7500, max_x: 20, max_y: 7503, source: "box-75", },
    { min_x: 0, min_y: 7600, max_x: 20, max_y: 7603, source: "box-76", },
    { min_x: 0, min_y: 7700, max_x: 20, max_y: 7703, source: "box-77", },
    { min_x: 0, min_y: 7800, max_x: 20, max_y: 7803, source: "box-78", },
    { min_x: 0, min_y: 7900, max_x: 20, max_y: 7903, source: "box-79", },
  ]
  let report = @gdsii.check_manhattan_drc(rects, 4, 5).unwrap()
  let pairs = []
  let widths = []
  for v in report.violations {
    match v {
      @gdsii.MinimumWidth(id, _) => widths.push(id)
      @gdsii.MinimumSpacing(a, b, d) => {
        pairs.push((a, b))
        assert_true(d >= 0.0 && d < 5.0)
      }
    }
  }
  pairs.sort_by(fn(a, b) {
    let c = a.0.compare(b.0)
    if c == 0 {
      a.1.compare(b.1)
    } else {
      c
    }
  })
  let expected_pairs : Array[(Int, Int)] = []
  let expected_widths : Array[Int] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41,
    42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61,
    62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
  ]
  assert_eq(pairs, expected_pairs)
  assert_eq(widths, expected_widths)
  assert_true(report.candidates >= pairs.length().to_int64())
}

///|
test "independent DRC random" {
  let rects : Array[@gdsii.Rect] = [
    { min_x: 116, min_y: 85, max_x: 139, max_y: 109, source: "box-0", },
    { min_x: 98, min_y: -177, max_x: 117, max_y: -155, source: "box-1", },
    { min_x: -92, min_y: -181, max_x: -76, max_y: -163, source: "box-2", },
    { min_x: -128, min_y: -66, max_x: -127, max_y: -51, source: "box-3", },
    { min_x: -81, min_y: 105, max_x: -74, max_y: 124, source: "box-4", },
    { min_x: 136, min_y: 197, max_x: 160, max_y: 199, source: "box-5", },
    { min_x: 99, min_y: -200, max_x: 106, max_y: -185, source: "box-6", },
    { min_x: 8, min_y: -20, max_x: 30, max_y: 2, source: "box-7", },
    { min_x: -96, min_y: -91, max_x: -81, max_y: -88, source: "box-8", },
    { min_x: 112, min_y: -93, max_x: 114, max_y: -71, source: "box-9", },
    { min_x: -158, min_y: -100, max_x: -142, max_y: -98, source: "box-10", },
    { min_x: 135, min_y: 75, max_x: 147, max_y: 80, source: "box-11", },
    { min_x: -121, min_y: 186, max_x: -116, max_y: 210, source: "box-12", },
    { min_x: 1, min_y: 164, max_x: 7, max_y: 172, source: "box-13", },
    { min_x: 52, min_y: -113, max_x: 60, max_y: -103, source: "box-14", },
    { min_x: -3, min_y: 123, max_x: 11, max_y: 133, source: "box-15", },
    { min_x: 153, min_y: -12, max_x: 159, max_y: -4, source: "box-16", },
    { min_x: -30, min_y: -149, max_x: -19, max_y: -133, source: "box-17", },
    { min_x: 184, min_y: 12, max_x: 208, max_y: 16, source: "box-18", },
    { min_x: -165, min_y: 52, max_x: -148, max_y: 69, source: "box-19", },
    { min_x: -44, min_y: 126, max_x: -39, max_y: 128, source: "box-20", },
    { min_x: 121, min_y: -187, max_x: 131, max_y: -181, source: "box-21", },
    { min_x: 68, min_y: -20, max_x: 73, max_y: -10, source: "box-22", },
    { min_x: -194, min_y: -144, max_x: -185, max_y: -131, source: "box-23", },
    { min_x: 171, min_y: 14, max_x: 182, max_y: 38, source: "box-24", },
    { min_x: 88, min_y: 177, max_x: 112, max_y: 199, source: "box-25", },
    { min_x: -5, min_y: 79, max_x: 4, max_y: 99, source: "box-26", },
    { min_x: 184, min_y: -87, max_x: 196, max_y: -67, source: "box-27", },
    { min_x: -122, min_y: -194, max_x: -110, max_y: -189, source: "box-28", },
    { min_x: 4, min_y: 177, max_x: 19, max_y: 181, source: "box-29", },
    { min_x: -44, min_y: 102, max_x: -42, max_y: 104, source: "box-30", },
    { min_x: 142, min_y: -145, max_x: 160, max_y: -142, source: "box-31", },
    { min_x: -104, min_y: 106, max_x: -82, max_y: 119, source: "box-32", },
    { min_x: -95, min_y: -19, max_x: -74, max_y: 4, source: "box-33", },
    { min_x: -57, min_y: 185, max_x: -44, max_y: 194, source: "box-34", },
    { min_x: 29, min_y: 98, max_x: 38, max_y: 103, source: "box-35", },
    { min_x: 84, min_y: -1, max_x: 92, max_y: 6, source: "box-36", },
    { min_x: -145, min_y: -88, max_x: -134, max_y: -84, source: "box-37", },
    { min_x: 63, min_y: 78, max_x: 64, max_y: 99, source: "box-38", },
    { min_x: -2, min_y: -151, max_x: 8, max_y: -146, source: "box-39", },
    { min_x: -93, min_y: -159, max_x: -84, max_y: -144, source: "box-40", },
    { min_x: 165, min_y: -96, max_x: 166, max_y: -72, source: "box-41", },
    { min_x: 71, min_y: 84, max_x: 72, max_y: 88, source: "box-42", },
    { min_x: -137, min_y: -66, max_x: -115, max_y: -43, source: "box-43", },
    { min_x: -135, min_y: 98, max_x: -119, max_y: 113, source: "box-44", },
    { min_x: 97, min_y: -48, max_x: 115, max_y: -27, source: "box-45", },
    { min_x: -104, min_y: 148, max_x: -96, max_y: 151, source: "box-46", },
    { min_x: -106, min_y: 81, max_x: -95, max_y: 103, source: "box-47", },
    { min_x: 176, min_y: 102, max_x: 198, max_y: 119, source: "box-48", },
    { min_x: 28, min_y: 37, max_x: 35, max_y: 38, source: "box-49", },
    { min_x: 127, min_y: -120, max_x: 128, max_y: -108, source: "box-50", },
    { min_x: 50, min_y: 162, max_x: 65, max_y: 168, source: "box-51", },
    { min_x: 178, min_y: 28, max_x: 184, max_y: 43, source: "box-52", },
    { min_x: 186, min_y: 148, max_x: 197, max_y: 150, source: "box-53", },
    { min_x: 42, min_y: 58, max_x: 43, max_y: 80, source: "box-54", },
    { min_x: -131, min_y: 58, max_x: -129, max_y: 69, source: "box-55", },
    { min_x: 0, min_y: 199, max_x: 12, max_y: 215, source: "box-56", },
    { min_x: -190, min_y: 12, max_x: -175, max_y: 29, source: "box-57", },
    { min_x: -28, min_y: -61, max_x: -12, max_y: -58, source: "box-58", },
    { min_x: 55, min_y: -144, max_x: 65, max_y: -121, source: "box-59", },
    { min_x: -158, min_y: 196, max_x: -151, max_y: 200, source: "box-60", },
    { min_x: -135, min_y: -164, max_x: -122, max_y: -151, source: "box-61", },
    { min_x: -1, min_y: -54, max_x: 12, max_y: -35, source: "box-62", },
    { min_x: -153, min_y: -146, max_x: -151, max_y: -134, source: "box-63", },
    { min_x: 66, min_y: -125, max_x: 73, max_y: -104, source: "box-64", },
    { min_x: -52, min_y: -34, max_x: -41, max_y: -19, source: "box-65", },
    { min_x: 178, min_y: 118, max_x: 182, max_y: 130, source: "box-66", },
    { min_x: 38, min_y: 18, max_x: 56, max_y: 40, source: "box-67", },
    { min_x: -60, min_y: 171, max_x: -42, max_y: 191, source: "box-68", },
    { min_x: 62, min_y: 62, max_x: 83, max_y: 64, source: "box-69", },
    { min_x: 83, min_y: 96, max_x: 89, max_y: 108, source: "box-70", },
    { min_x: -33, min_y: 26, max_x: -14, max_y: 37, source: "box-71", },
    { min_x: -26, min_y: -104, max_x: -13, max_y: -94, source: "box-72", },
    { min_x: -134, min_y: 158, max_x: -116, max_y: 164, source: "box-73", },
    { min_x: 61, min_y: -27, max_x: 63, max_y: -13, source: "box-74", },
    { min_x: -49, min_y: -68, max_x: -40, max_y: -49, source: "box-75", },
    { min_x: 178, min_y: -85, max_x: 183, max_y: -70, source: "box-76", },
    { min_x: 168, min_y: 144, max_x: 186, max_y: 145, source: "box-77", },
    { min_x: -21, min_y: -122, max_x: 1, max_y: -116, source: "box-78", },
    { min_x: 88, min_y: 4, max_x: 98, max_y: 17, source: "box-79", },
    { min_x: 177, min_y: -200, max_x: 198, max_y: -190, source: "box-80", },
    { min_x: 98, min_y: -36, max_x: 122, max_y: -28, source: "box-81", },
    { min_x: 143, min_y: -193, max_x: 155, max_y: -189, source: "box-82", },
    { min_x: 163, min_y: 92, max_x: 181, max_y: 106, source: "box-83", },
    { min_x: 66, min_y: -170, max_x: 82, max_y: -162, source: "box-84", },
    { min_x: -56, min_y: 101, max_x: -35, max_y: 125, source: "box-85", },
    { min_x: -52, min_y: -57, max_x: -32, max_y: -35, source: "box-86", },
    { min_x: 28, min_y: -144, max_x: 52, max_y: -129, source: "box-87", },
    { min_x: 160, min_y: 76, max_x: 184, max_y: 83, source: "box-88", },
    { min_x: -10, min_y: -196, max_x: -1, max_y: -186, source: "box-89", },
    { min_x: -138, min_y: 137, max_x: -125, max_y: 156, source: "box-90", },
    { min_x: -59, min_y: -191, max_x: -49, max_y: -167, source: "box-91", },
    { min_x: 98, min_y: 113, max_x: 106, max_y: 122, source: "box-92", },
    { min_x: 22, min_y: -147, max_x: 33, max_y: -139, source: "box-93", },
    { min_x: -117, min_y: 38, max_x: -99, max_y: 42, source: "box-94", },
    { min_x: 11, min_y: 98, max_x: 27, max_y: 104, source: "box-95", },
    { min_x: -159, min_y: -181, max_x: -145, max_y: -168, source: "box-96", },
    { min_x: -48, min_y: -118, max_x: -32, max_y: -101, source: "box-97", },
    { min_x: -133, min_y: 69, max_x: -110, max_y: 92, source: "box-98", },
    { min_x: -136, min_y: -91, max_x: -127, max_y: -80, source: "box-99", },
    { min_x: -52, min_y: -82, max_x: -36, max_y: -61, source: "box-100", },
    { min_x: 155, min_y: -105, max_x: 176, max_y: -81, source: "box-101", },
    { min_x: -135, min_y: -2, max_x: -123, max_y: -1, source: "box-102", },
    { min_x: 112, min_y: -124, max_x: 115, max_y: -114, source: "box-103", },
    { min_x: -110, min_y: 46, max_x: -95, max_y: 58, source: "box-104", },
    { min_x: -27, min_y: 13, max_x: -16, max_y: 27, source: "box-105", },
    { min_x: 116, min_y: 154, max_x: 122, max_y: 158, source: "box-106", },
    { min_x: -189, min_y: -169, max_x: -169, max_y: -146, source: "box-107", },
    { min_x: 139, min_y: -132, max_x: 145, max_y: -125, source: "box-108", },
    { min_x: 54, min_y: 164, max_x: 65, max_y: 166, source: "box-109", },
    { min_x: -186, min_y: -125, max_x: -179, max_y: -105, source: "box-110", },
    { min_x: 135, min_y: -111, max_x: 151, max_y: -103, source: "box-111", },
    { min_x: -95, min_y: 50, max_x: -83, max_y: 68, source: "box-112", },
    { min_x: -149, min_y: -167, max_x: -134, max_y: -145, source: "box-113", },
    { min_x: -29, min_y: 41, max_x: -12, max_y: 55, source: "box-114", },
    { min_x: 9, min_y: -135, max_x: 33, max_y: -122, source: "box-115", },
    { min_x: -58, min_y: 16, max_x: -54, max_y: 36, source: "box-116", },
    { min_x: 37, min_y: 129, max_x: 46, max_y: 133, source: "box-117", },
    { min_x: 66, min_y: 16, max_x: 67, max_y: 22, source: "box-118", },
    { min_x: 58, min_y: 2, max_x: 66, max_y: 18, source: "box-119", },
  ]
  let report = @gdsii.check_manhattan_drc(rects, 7, 13).unwrap()
  let pairs = []
  let widths = []
  for v in report.violations {
    match v {
      @gdsii.MinimumWidth(id, _) => widths.push(id)
      @gdsii.MinimumSpacing(a, b, d) => {
        pairs.push((a, b))
        assert_true(d >= 0.0 && d < 13.0)
      }
    }
  }
  pairs.sort_by(fn(a, b) {
    let c = a.0.compare(b.0)
    if c == 0 {
      a.1.compare(b.1)
    } else {
      c
    }
  })
  let expected_pairs : Array[(Int, Int)] = [
    (0, 11),
    (0, 92),
    (1, 6),
    (1, 21),
    (2, 40),
    (3, 43),
    (4, 32),
    (10, 37),
    (10, 99),
    (13, 29),
    (14, 59),
    (14, 64),
    (17, 78),
    (18, 24),
    (18, 52),
    (20, 85),
    (21, 82),
    (22, 74),
    (22, 119),
    (23, 107),
    (23, 110),
    (24, 52),
    (26, 95),
    (27, 76),
    (27, 101),
    (30, 85),
    (31, 108),
    (32, 47),
    (34, 68),
    (35, 95),
    (36, 79),
    (37, 99),
    (38, 42),
    (39, 115),
    (41, 76),
    (41, 101),
    (44, 98),
    (45, 81),
    (47, 98),
    (48, 66),
    (48, 83),
    (49, 67),
    (50, 103),
    (50, 108),
    (50, 111),
    (51, 109),
    (53, 77),
    (55, 98),
    (58, 62),
    (58, 75),
    (58, 86),
    (58, 100),
    (59, 64),
    (59, 87),
    (61, 96),
    (61, 113),
    (63, 113),
    (65, 86),
    (66, 83),
    (67, 118),
    (67, 119),
    (70, 92),
    (71, 105),
    (71, 114),
    (72, 78),
    (72, 97),
    (73, 90),
    (75, 86),
    (75, 100),
    (76, 101),
    (78, 97),
    (78, 115),
    (83, 88),
    (86, 100),
    (87, 93),
    (87, 115),
    (93, 115),
    (94, 104),
    (94, 112),
    (96, 107),
    (96, 113),
    (98, 104),
    (101, 111),
    (104, 112),
    (118, 119),
  ]
  let expected_widths : Array[Int] = [
    3, 5, 8, 9, 10, 11, 12, 13, 16, 18, 20, 21, 22, 28, 29, 30, 31, 35, 37, 38, 39,
    41, 42, 46, 49, 50, 51, 52, 53, 54, 55, 58, 60, 63, 66, 69, 70, 73, 74, 76, 77,
    78, 82, 94, 95, 102, 103, 106, 108, 109, 116, 117, 118,
  ]
  assert_eq(pairs, expected_pairs)
  assert_eq(widths, expected_widths)
  assert_true(report.candidates >= pairs.length().to_int64())
}

///|
test "independent DRC int32-extremes" {
  let rects : Array[@gdsii.Rect] = [
    {
      min_x: -2147483648,
      min_y: -2147483648,
      max_x: -1,
      max_y: -1,
      source: "box-0",
    },
    {
      min_x: 0,
      min_y: 0,
      max_x: 2147483647,
      max_y: 2147483647,
      source: "box-1",
    },
    { min_x: -2, min_y: -2, max_x: 2, max_y: 2, source: "box-2", },
  ]
  let report = @gdsii.check_manhattan_drc(rects, 3, 2147483647).unwrap()
  let pairs = []
  let widths = []
  for v in report.violations {
    match v {
      @gdsii.MinimumWidth(id, _) => widths.push(id)
      @gdsii.MinimumSpacing(a, b, d) => {
        pairs.push((a, b))
        assert_true(d >= 0.0 && d < 2147483647.0)
      }
    }
  }
  pairs.sort_by(fn(a, b) {
    let c = a.0.compare(b.0)
    if c == 0 {
      a.1.compare(b.1)
    } else {
      c
    }
  })
  let expected_pairs : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
  let expected_widths : Array[Int] = []
  assert_eq(pairs, expected_pairs)
  assert_eq(widths, expected_widths)
  assert_true(report.candidates >= pairs.length().to_int64())
}
