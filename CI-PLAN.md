# CI acceptance

The current module is `tanglong2001-2/gdsii`, maintained in
`tanglong2001-2/moonbit-gdsii`. Public consumer packages use this exact import;
generated interfaces come from the pinned SDK. Source provenance, licenses and
Git authorship remain intact. Verification binds actual fresh namespace builds,
public consumers and file inputs/outputs, rather than a string-replacement test.

## Raw definition inventory and physical spans

The new consumer question is which exact named cell record blocks changed when
receiving two GDS revisions. A growing earlier cell changes later offsets without
changing those later definitions. Dates/properties/opaque records are outside the
finding-only comparison purpose. That existing boundary is not a bug. A standalone
first-byte utility alone has insufficient value; the selected workflow provides
name-aware states, full spans, complete report and an actual block recipient.

Compare full kind/datatype/payload sequences including dates, ignoring offsets;
before order plus after-only names, no rename inference or graph expansion. Outside
record sequence/order/padding views do not establish full physical equality.
Independently compare physical bytes and first mismatch. The moved-library-record
case deliberately leaves all component flags true while bytes differ.

- Freeze nine original GDS streams, complete record tables/cell blocks and eleven
  full inventories before implementation/execution. Include shifted offsets,
  properties, dates, membership/order, library fields, physical padding, moved
  outside records and empty sides/both empty. Distribution and embedded/doc-example
  streams must match their frozen originals; no product-derived expectations.
- Six new public blackbox groups on JS/Wasm-GC plus relevant JS build/check,
  formatting and generated API review. The public addition is metadata only.
  Use explicit nullable JSON for the new types, without changing default Option
  serialization or any old API. Use the public Json::null factory for null values
  and explicitly qualified trait serialization calls.
  Compiler diagnostics and unchanged frozen expected values are part of the clean
  verification pass.
- `node .ci/definition_diff.mjs` executes actual file producers/recipients, compares
  all complete reports and independently frozen block bytes/SHA, global parse and
  filesystem failures, refusal and stale operands. Prefix every process log to
  keep it distinct from input artifacts; persist full process results before
  assertions. Assert complete Checks notices below3900bytes, retain full artifacts.
- Keep every old necessary job/gate and add **Verify raw definition inventory and
  physical cell spans** in **JS, Wasm-GC and file consumers**. Full native tests
  exercise the portable public addition; current native CI remains separate from
  old retained local native/cache outputs. Do not rerun unchanged local targets,
  accepted workflows or scientific reference generators.
- Freeze final-head source ZIP/member readback and README/PROPOSAL/this plan;
  distinguish Git blob content/raw/test copies, actual inputs/engine, local compiled
  outputs and full raw processes. Exact-head required CI/check URLs/notices and
  cloud artifact metadata do not imply cloud binary/archive downloads or local/cloud
  equality. Verification records bind source, consumed binary and runtime output.

This is strict record inventory, not minimal edit distance, full CAD/semantic
equality, hidden vendor interpretation, report authenticity, causal geometry or
future filesystem stability. No parser/writer/geometry/reverse/plan behavior,
format/model, SDK, dependency or source-author changes are included. Namespace
alignment changes package identity and imports while preserving public symbols
and behavior.

## Saved two-revision comparison plans

The new consumer question is whether two revisions regress under one saved named
rule plan. Single-source saved plans and single-profile pair comparisons already
compose; the missing workflow is one complete per-ID, three-input comparison
handoff that retains both sides even when either fails. Arbitrary caller-forged
report integrity auditing is not an existing promise and is not added.

Reuse the strict `gdsii-rectangle-review-plan-v1` and public finding diff without
changing any portable API or geometry model. Validate the entire plan before
parsing either revision; parse each once, evaluate each side/profile with fresh
budgets, preserve both errors/reports, then compare if both succeeded. Save all
results and bind before/after/plan raw snapshots to one physical JSON report.
The recipient verifies all three current inputs before displaying outcomes.

- Independent original streams, raw plans and eight complete expected report
  objects in `testdata/comparison-plan-vectors.json` are frozen before code/run.
  They cover regression, retained/reordered baseline issues, mixed empty/skipped
  coverage, both distinct side errors, per-side budgets, DBU mismatch and missing
  selected cells. Full objects include both preflights and the existing diff.
- Run the changed JS check/build, formatting and interface review locally. This
  is a JS-only private command; no portable library behavior/signature changed,
  so no duplicate local old JS/Wasm/native or scientific-generator runs.
- `node .ci/compare_plan.mjs` executes the actual compiled producer and physical
  recipient for every complete case, relevant existing pair receivers, global
  before/after/plan errors, output/input refusal and stale three-input handoffs.
  Retain full stdout/stderr/exits and actual saved bytes. Always assert the complete
  Checks notice stays below3900bytes; keep full manifests in the uploaded artifact.
- Keep all existing required jobs/steps; add **Verify saved two-revision
  comparison plan receivers** to **JS, Wasm-GC and file consumers**. The existing
  full JS/Wasm-GC/native checks and direct native consumers remain required CI.
- Freeze final README/PROPOSAL/this plan, every source ZIP member, actual local
  compiler/consumed engine, original input/test-copy/raw-output identities and
  exact-head required CI. Cloud notices/metadata are distinct from downloaded
  binary/archive readback; local/cloud engine bytes need not match.

ErrorsFound/2 precedes Incomplete/4, NewIssuesFound/3 and NoNewIssues/0. Incomplete
coverage prevents regression acceptance even if findings exist. NoNewIssues may
retain baseline violations; the workflow does not claim full CAD equivalence,
report authentication, external adoption or future filesystem stability. Current
verification requires the saved report, current-input receipt and necessary CI.

## Reference-impact review acceptance

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
capability is included. Compile success and cloud artifact metadata alone do not
establish physical output readback or runtime acceptance.
