# Reference-impact review acceptance

The consumer question is which known definitions require review after editing or
repairing a shared cell symbol. Existing catalog and hierarchy expose composable
forward metadata. Top-only preflight omits components with no roots and can include
unrelated broken tops. This change adds one complete reverse-query/review workflow,
without changing the existing graph, geometry, rename or extraction contracts.

`reference_impact` returns source-order definitions, including the defined target,
and one shortest supported SREF/AREF definition path. Reverse BFS uses incoming
source-cell/element order for ties. An unresolved target has its real callers;
an unreferenced unknown name has none. Arrays are fresh; array instances are not
expanded. Whole-cell preflight produces a source-bound saved report for every
known impacted definition, including errors. A separate file recipient checks
the report against the current source before presenting its queue.

The independent graph paths and numerical expectations were frozen before
implementation. `testdata/reference-impact-vectors.json` retains complete reports
with hand-positioned rectangles and hand-selected dependency witnesses. One NODETYPE
input-encoding correction was made before product execution. The first physical
attempt then exposed an expected-JSON representation mismatch: the pinned SDK
serializes Int64 counters as strings. Only that representation was corrected
after checking the pinned core; graph and numerical expectations were retained.
Initial streams/expectations and the failed actual output remain in round
evidence. The gate never generates expected reports from the library.

Required verification:

- New blackbox API groups cover shared/AREF callers, direct/shortest-tie paths,
  unresolved/exact names, rootless cycles/ancestor scope and source isolation.
  Run targeted groups locally on JS and Wasm-GC; CI runs full supported suites.
- Build the actual JS command. `node .ci/reference_impact.mjs` produces 12 complete
  physical JSON reports, compares every report object with independent expected
  output, reads each through the separate example recipient and retains complete
  process stdout/stderr/exit status. It also exercises the existing preflight
  file consumer on relevant new source/profile combinations.
- The same gate checks empty inventory/selection, rootless cycles, dangling
  targets, violation-plus-skip coverage, fresh per-cell budgets, malformed/missing
  input, invalid profiles, existing/source output refusal, missing destination
  directory and actual stale-source rejection. Error2 from a per-cell result is
  distinguished from a producer failure: the former still has a complete report.
- Keep all previous required CI steps. Add the necessary step **Verify
  reference-impact review file receivers** in **JS, Wasm-GC and file consumers**.
  **Linux native public API consumers** also runs the new portable library tests
  in its full suite and retains the existing direct native applications.
- Review formatting/generated interfaces, source-only archive members and exact
  final-head CI run/jobs/steps. Identify working-source, test-copy, actual consumed
  JS binary, local compiled/cache and full raw-output domains separately. A source
  archive is not a compiled output archive. Hash notices and cloud artifact
  metadata do not establish downloaded cloud-binary readback.

The required workflow passes only when the saved report and receiver preserve
all ordered results and exact witnesses; errors take precedence, then incomplete
coverage/empty queues, then findings, then pass. Counts are per cell report.
These are project-authored consumers, not external adoption or physical signoff.
No package publication, contest submission, new CAD format or geometry expansion
capability is included. A round receipt awaits independent root acceptance;
neither CI success nor this file increments the accepted-round counter.
