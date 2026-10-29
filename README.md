# GDSII for MoonBit

Native GDSII binary records, REAL8 numerics, hierarchy expansion and rectangle preflight.
Module: `tanglong2001-2/gdsii`.
Current maintainer and submission account: `tanglong2001-2`.
Source repository: [tanglong2001-2/moonbit-gdsii](https://github.com/tanglong2001-2/moonbit-gdsii).

Original source attribution remains `tanglong2001`; copyright notices and Git
authorship history are preserved. Repository ownership does not change authorship.

Public consumer packages import `tanglong2001-2/gdsii` (the default alias is
`@gdsii`). Existing consumers must update their own import namespace; exported
symbols and behavior are preserved. Build and run from this source checkout.

The library has no external MoonBit dependencies. CI covers JS and Wasm-GC plus
Linux x86-64 native core consumers on Ubuntu 24.04. The optional file consumer uses
Node.js and remains JS-only. Validated toolchain: moonc 0.10.12,
moon 0.1.20260904. Public signatures are in `pkg.generated.mbti`.

GitHub Actions checks and builds both portable targets, runs the full test suite and portable
example, and verifies the authored GDS bytes through the real Node file consumers.
The SDK, core archives and Actions are pinned by version and SHA-256/commit in
`.ci/toolchain.json` and `.github/workflows/ci.yml`; Node.js is fixed at 24.11.0.
Each run retains its commit, source hashes, tool versions and consumer evidence
as the `gdsii-ci-<commit>` artifact.

## Run

```sh
moon check --target js
moon build --target js
moon test --target js
moon test --target wasm-gc
moon run cmd/example --target js
moon run cmd/example --target wasm-gc
moon run cmd/author --target js
moon run cmd/author --target wasm-gc
node tools/inspect.mjs --catalog examples/demo.gds
node tools/inspect.mjs --hierarchy examples/demo.gds top
node tools/inspect.mjs examples/demo.gds top 7 2 3 5
node tools/inspect.mjs --preflight examples/demo.gds top 7 2 3 5
node tools/inspect.mjs --compare examples/revision-before.gds examples/revision-after.gds top 7 2 3 3
node tools/inspect.mjs --preflight-tops examples/multi-top-before.gds 7 2 3 3
node tools/inspect.mjs --compare-tops examples/multi-top-before.gds examples/multi-top-after.gds 7 2 3 3
node tools/inspect.mjs --review-plan examples/review-plan.gds examples/review-plan.json
node tools/extract_cell.mjs examples/cell-extract-source.gds top exported-top.gds
node tools/rename_cell.mjs examples/cell-rename-source.gds gate coreA renamed.gds
node tools/review_dependents.mjs examples/reference-impact.gds mid 18 0 5 0 mid-review.json
node examples/read_dependent_review.mjs mid-review.json
node tools/compare_plan.mjs examples/comparison-plan-before.gds examples/comparison-plan-after.gds examples/comparison-plan.json comparison-review.json
node examples/read_comparison_plan.mjs comparison-review.json
node tools/definition_diff.mjs examples/definition-diff-before.gds examples/definition-diff-after.gds definition-review.json
node examples/read_definition_diff.mjs definition-review.json
```

## Remap layer and type tags

Use `lib.remap_layers(mappings)` to retarget the original `(layer, type)` pairs
in every BOUNDARY, PATH, BOX, NODE and TEXT definition. For TEXT the type is
TEXTTYPE; NODE uses NODETYPE and BOX uses BOXTYPE. References keep their original
targets and placements, including unresolved references or cycles. The operation
does not expand the hierarchy or interpret geometry.

Each public `LayerRemap` has `from_layer`, `from_type`, `to_layer`, `to_type`, all
integers from 0 through 65535. Every rule is checked before applying any rule;
duplicate source pairs are errors, including identical or unmatched rules.
Mappings are simultaneous: `1/2 -> 3/4` and `3/4 -> 9/10` send original `1/2`
elements to `3/4`. They are not subsequently sent to `9/10`. Swaps and shared
destinations are supported without deleting or reordering elements. Empty maps,
identity maps and unmatched source pairs are valid.

Only the matched LAYER and kind-specific type payloads change. Coordinates,
path widths/extensions, text, properties, repeated unknown records, timestamps,
units, record headers/offsets, cell order and physical zero padding stay exact.
The original library is unchanged, and the result owns independent parsed arrays.
In particular, a no-op preserves the complete input byte stream.

For a physical GDS handoff, use the supplied source and map:

```sh
moon build --target js
node tools/remap_layers.mjs examples/layer-remap-source.gds examples/layer-remap.json remapped.gds > remap-receipt.json
node examples/read_remapped_layers.mjs remap-receipt.json
node tools/inspect.mjs --catalog remapped.gds
```

The UTF-8 map accepts one leading BOM and has exactly this schema:

```json
{
  "schema": "gdsii-layer-remap-v1",
  "mappings": [
    { "from_layer": 1, "from_type": 2, "to_layer": 7, "to_type": 8 }
  ]
}
```

Unknown map/rule fields, missing fields, fractions, out-of-range integers and
duplicate source pairs reject the whole map before GDS parsing. The example
changes five definitions, one of each supported tag-bearing kind. Its references,
opaque records, properties, geometry and seven physical trailing zero bytes are
preserved. The unsigned 16-bit extremes are supported, as are empty libraries.

The producer snapshots the plan and source once, calls the public MoonBit method,
exclusively creates the output GDS and reads it back. Stdout is a complete JSON
receipt binding the original source, exact plan bytes and actual output to their
paths/lengths/SHA256, with the changed element count and complete output catalogue.
Successful edits and no-ops exit 0; input, plan, engine or I/O errors exit 2.
Existing files, including source and plan paths, are refused. Late I/O failure can
leave a partial new output; the output and shell-redirected receipt are not a
transaction.

The separate recipient reads the saved receipt and all three current physical
files. It independently scans record headers and tag payloads, verifies every
byte against the simultaneous replacement contract, and prints the actual tag
inventory, changed record/byte offsets and padding length. A changed source,
plan or output is rejected. This own recipient demonstrates file consumption;
it does not establish external adoption, receipt author authenticity, future file
stability, fabrication readiness or geometric equivalence.

## Raw definition change inventory

`before.definition_diff(after)` compares complete cell record blocks by exact
name without expanding hierarchy or geometry. It helps locate revised definitions
when an earlier edit shifts every later file offset, or when properties, dates,
unsupported shapes or opaque bytes change outside selected rectangle findings.
Existing `records()` and ordinary byte comparison are composable primitives;
this API packages the name-aware inventory and usable raw ranges. Existing finding
comparisons keep their stated meaning and are not treated as defective.

The result gives fresh `before_cells`/`after_cells` source-order names. Its `cells`
union follows before order, then after-only names. Each entry has an exact `name`,
`DefinitionAdded`, `DefinitionRemoved`, `DefinitionChanged` or
`DefinitionUnchanged`, and optional `before`/`after` `CellRecordSpan` values.
Spans contain zero-based `first_record`, `record_count`, `byte_offset` and
`byte_length`, including the complete BGNSTR..ENDSTR block in `to_bytes()` output.
STRNAME need not immediately follow BGNSTR. Identity compares record kind, datatype
and full payload sequence, including dates/unknown records; offsets are ignored.
There is no rename inference. Missing and cyclic references remain unexpanded data.

`library_records_equal` compares the sequence of records outside cells, ignoring
their placement among cells. `cell_order_equal` compares name order and
`padding_equal` compares exact physical trailing zeros. Independently,
`bytes_equal` compares the full physical byte streams and `first_difference` is
the first same-index mismatch (or shorter length for a strict prefix). A moved
library record can leave all three component flags true while physical bytes
differ: **do not combine those flags to infer whole-file equality**. These are raw
comparison views, not a minimal record edit script or semantic/CAD equivalence.

```sh
node tools/definition_diff.mjs BEFORE.gds AFTER.gds OUTPUT.json
node examples/read_definition_diff.mjs OUTPUT.json
```

The producer reads each operand once, parses both and exclusively creates a
complete `gdsii-definition-diff-v1` JSON report bound to both raw paths, lengths and
SHA-256 snapshots. Wire ranges and first offset are nullable objects/numbers;
native API fields are Options. Output is physically read back and its actual
length/SHA-256 returned. Identical physical bytes exit0, changed bytes exit3,
global parse/input/I/O errors exit2 without a valid report. The supplied example
exits3: alpha grows by16bytes, while beta/gamma remain unchanged at shifted offsets.
Existing inputs/output are refused; late I/O may leave a partial new file.

The separate recipient reads the physical report and current source snapshots,
decodes record headers to extract each declared complete cell block, checks its
STRNAME/boundaries and prints actual block lengths/ranges/SHA-256 plus the first
physical byte mismatch. It does not need the geometry engine. A stale source is
rejected at receipt time; this is not author authentication or future file
stability. Project receivers are not external adoption. No hidden/vendor reference
semantics, geometry equivalence or finding/causal conclusions are inferred.

After a JS build, `node .ci/definition_diff.mjs` verifies eleven independently
frozen complete inventories and actual span bytes, global/refusal/stale errors and
new public blackbox tests cover JS/Wasm-GC. Original CC0 streams, record tables and
cell bytes are in `testdata/definition-diff-vectors.json`. A fresh gate output
directory is optional. [gdstk.read_rawcells](https://heitzmann.github.io/gdstk/library/gdstk.read_rawcells.html)
is a primary example of raw cells indexed by name; no gdstk code/runtime or previous
scientific reference generator is used by this workflow.

## Saved plans for two-revision regression review

`tools/compare_plan.mjs BEFORE.gds AFTER.gds PLAN.json OUTPUT.json` applies the
existing `gdsii-rectangle-review-plan-v1` plan to both revisions. Saved single-source
plans and single-profile `--compare` remain available; they can be composed by
callers. This command supplies one complete, named-rule regression handoff using
the same cell, selectors, thresholds and budget on both sides.

The plan keeps its existing strict fields, unique nonempty IDs, explicit
nonnegative INT32 selectors/rules and optional positive INT32 budget (100000 by
default). UTF-8 accepts one initial BOM. Each input operand is read once; the
engine validates the whole plan before GDS parsing, then parses each revision
once. Each profile and revision receives a fresh budget. Both sides are evaluated
even if one fails, preserving both errors or complete preflights under that ID.
When both succeed, the existing finding-multiset `PreflightReport.diff` runs;
comparison errors, including differing report DBU metadata, retain both reports.
Later IDs are always evaluated after per-profile errors. Global plan/parse errors
return one error without a partial review.

The saved `gdsii-rectangle-comparison-result-v1` JSON contains `before`, `after`
and `plan` absolute-path/length/SHA-256 snapshots, plus ordered profiles, both
preflight results, comparisons, counts and coverage. Status precedence is
ErrorsFound/2, Incomplete/4, NewIssuesFound/3, NoNewIssues/0. Counts are profiles,
named `errors`, `incomplete`, `new_issues` and `no_new_issues`. Coverage is complete
only when every requested comparison has checked rectangles on both sides and no
skips/errors; `coverage.unchecked_profiles` identifies the rest. NoNewIssues may
retain baseline violations and does not mean clear geometry or physical equivalence.
The supplied example saves a report and exits3: one width finding disappears and
a different one is introduced; its second profile remains clear.

Output is exclusively created and read back before printing its actual byte
length/SHA-256. Per-profile errors still save the complete review and return2;
request/input/global plan/parse/I/O errors do not create a valid report. Existing
files, including all three inputs, are refused. Late I/O can leave a partial new
file; no filesystem transaction is promised. The separate recipient example reads
the physical report, verifies all three current input snapshots and displays the
ordered outcomes. This is a receipt-time check, not future file stability or
report-author authentication. Both tools are project consumers, not external adoption.

After building JS, `node .ci/compare_plan.mjs` checks eight independent complete
reports, both-side failures, retained/reordered findings, incomplete coverage,
fresh budgets, DBU mismatch, global failures, output refusal and actual stale
before/after/plan handoffs. It retains full files and process outputs; a fresh
output directory is its optional argument. Original CC0 data/expectations are in
`testdata/comparison-plan-vectors.json`. The command bridge is JS-only; the portable
public library and its geometry/diff APIs are unchanged. KLayout's documented
[`LayoutDiff`](https://www.klayout.de/doc/code/class_LayoutDiff.html) is a broader
layout-comparison tool; this project compares only the declared rectangle findings.

## Review definitions that depend on a symbol

When a shared cell changes, `lib.reference_impact("leaf")` inventories every known
definition that can reach that exact symbol through supported SREF/AREF references.
It includes a defined target itself with an empty witness. Cells follow source
definition order; each carries `is_top` and one shortest reference-edge `witness`.
The witness uses existing catalog metadata, including element index and AREF
columns/rows/instances. AREF is one graph edge, without expanding its instances.
Reverse breadth-first discovery visits incoming edges in source-cell/element order
and retains the first shortest tie. Returned arrays cannot mutate the library.

An undefined symbol can still have known callers: querying `ghost` in the supplied
sample returns `waiting` with an unresolved witness. An unknown, unreferenced exact
name returns an empty inventory. Names are not trimmed. Cyclic components are
included even when they have no top cell. This is potential definition dependency,
not a list of changed instance locations or a geometry validity claim. Catalog
and forward hierarchy remain useful composable primitives; the new API and file
workflow package the reverse query and its review handoff.

```sh
node tools/review_dependents.mjs SOURCE.gds TARGET LAYER DATATYPE WIDTH SPACING OUTPUT.json [BUDGET]
node examples/read_dependent_review.mjs OUTPUT.json
```

The producer reads one source snapshot, parses it once and preflights each impacted
known definition once with a fresh expansion budget (default 100000). Rules use
input DBU; all selectors/thresholds are explicit nonnegative INT32 integers and
budget is a positive INT32 integer. Each result reviews the **whole cell**; issues
are not attributed specifically to the changed symbol. The complete saved JSON
contains the source path/byte length/SHA-256, exact dependency witnesses, profile,
ordered results, report counts and unchecked coverage. The producer exclusively
creates the output, reads it back and prints its actual byte length/SHA-256.
Existing files, including the source, are refused. A late filesystem failure may
leave a partial newly created file; there is no atomic filesystem transaction.

Exit/status precedence is ErrorsFound/2, then Incomplete/4 for an empty queue or
any unchecked cell, then IssuesFound/3 for findings, otherwise Passed/0. Counts
count cell reports, not individual issues. Coverage requires a nonempty queue,
checked rectangles and no skipped/error cells. Per-cell errors still produce a
complete report and later cells are reviewed; global parse/profile/I/O errors do
not produce a valid report. Thus `leaf` in the sample saves a report and exits2
because two dependent definitions form a rootless cycle; `mid` reviews only
`mid` and `top` and exits0. Unrelated `waiting` does not enter that queue.

The separate recipient example reads the physical report and verifies the current
source bytes against its snapshot before presenting the ordered outcomes and
witnesses. A changed or unavailable source prevents receipt. This check is made
at receipt time; it does not guarantee future file stability or authenticate a
report author. Both producer and recipient are project examples, not evidence of
third-party adoption. Existing rectangle/unsupported-geometry/signoff limits apply.

After building JS, `node .ci/reference_impact.mjs` checks independently frozen
complete reports, actual saved files and recipients, existing file preflight,
rootless cycles, missing symbols, shortest ties, skips, budget errors, stale
handoffs and output refusal. Original CC0 inputs/expectations are in
`testdata/reference-impact-vectors.json`; the gate accepts a fresh output directory.
The reverse-caller use case also appears in KLayout's documented
[`Cell.caller_cells`](https://www.klayout.de/doc/code/class_Cell.html#caller_cells)
API. No KLayout code or runtime is included.

Selected-cell modes take cell, layer, datatype, minimum width and minimum spacing;
the top-candidate modes omit cell. All geometry/rule values are in input database
units (DBU). The Node wrapper streams the binary file as hex
over stdin to the compiled MoonBit consumer. Positional mode returns all flattened
shapes, per-instance source paths, selected rectangles, skipped-geometry findings,
violations and actual sweep/index work counters. Exit 2 means a parse/request/
hierarchy error. Geometry warnings must be considered before making a layout-level
decision; zero rectangle violations does not certify unchecked geometry.

For a child with a nonzero completion status, the wrapper returns one structured
`ENGINE_EXIT` response and exit2, including its status/diagnostic, even if it
already emitted a plausible comparison result. A child that completes with zero
status but emits truncated JSON returns `ENGINE_RESPONSE_INVALID` and exit2.
After `moon build --target js`, run `node .ci/wrapper_failures.mjs` to check
this two-file review boundary with a real compiled control and two isolated
external child faults. The gate checks complete original input bytes, exact
requests, stdout/stderr, exit codes and unchanged files. Choose a fresh output
directory as its optional argument to retain another local attempt. Controlled
fault payloads test transport; the legitimate control uses the actual GDS core.

Expansion commands accept an optional final positive INT32 `budget` after
spacing. Supply all preceding selectors/thresholds when setting it:

```sh
node tools/inspect.mjs --preflight layout.gds top 7 2 3 5 200000
node tools/inspect.mjs --compare-tops before.gds after.gds 7 2 3 5 200000
```

This applies to positional inspection, `--preflight`, `--compare`,
`--preflight-tops` and `--compare-tops`. Omission keeps 100000. The budget counts
visited cell instances and emitted shapes before layer selection; it ranges from
1 to 2147483647. Each candidate and each comparison revision receives a fresh
budget. Exceeding it returns `ExpansionLimit` with the chosen limit, preserving
candidate/side errors and later batch results. It does not return truncated
geometry. The existing hierarchy depth, coordinate and output limits still apply.
Catalogue/hierarchy inventory does not expand geometry or consume this budget.

For an unfamiliar file, start with `--catalog`: it needs no cell name or layer
selectors. Its JSON lists each cell's element definitions, references and
per-kind layer/type counts, top-cell candidates, missing targets and DBU units.
Choose a cell, then use `--hierarchy file.gds cell` to see its reachable layers
and reference problems before choosing a layer/type for the preflight command.
Use `--preflight` for the source-located summary and a result-specific exit code;
the positional command remains available for the full geometry/low-level output.

## Library

```moonbit nocheck
let library = @gdsii.GdsLibrary::parse(bytes).unwrap()
let catalog = library.catalog() // inspect definitions without expanding arrays
let target = library.hierarchy("top").unwrap() // reachable layers and graph findings
let original_bytes = library.to_bytes() // raw records and zero padding preserved
let flat = library.flatten_cell("top", budget=100000).unwrap()
let selection = flat.rectangles(7, 2) // explicit layer AND datatype
let findings = @gdsii.check_manhattan_drc(selection.rects, 3, 5).unwrap()
let report = library.preflight_cell("top", 7, 2, 3, 5).unwrap()
```

`GdsLibrary::from_records` is the checked record-based creation/rewrite entry.
`cells()` returns a newly parsed semantic view, so caller array edits cannot alter
the original library. `records()` exposes immutable payloads in a copied array.
Errors carry record offsets, missing cell names, cycle paths or numerical failures.

For a rewrite, replace records in that copied array, pass the complete array to
`from_records`, and serialize the returned `Ok` library. Record offsets are
recomputed; physical zero padding from the parsed input is not inherited. Keep
unrelated payloads, including REAL8 words, as their original bytes.

After `moon build --target js`, `node .ci/record_rewrite.mjs` checks a complete
property rewrite on JS and Wasm-GC against independently constructed GDS bytes.
It materializes and reads back both files, and passes a rejected rewrite to the
existing file materializer to verify that no output directory is created.

## Export one cell and its dependencies

`GdsLibrary::extract_cell(cell)` returns a newly validated library containing the
exact selected definition and its transitive known SREF/AREF dependencies. Each
definition appears once in original file order, including shared descendants.
Non-cell library records and complete retained BGNSTR..ENDSTR blocks keep their
kind, data type, payload and order: dates, properties, placements, opaque records
and both raw UNITS words are copied rather than rebuilt from semantic elements.

```moonbit nocheck
let component = library.extract_cell("top").unwrap()
let component_bytes = component.to_bytes()
```

The source stays unchanged. Exported offsets are recomputed and physical trailing
zero padding is omitted, following `from_records`. Closed reference cycles are
preserved as parseable data; extraction neither expands nor repairs them, and
their catalogue may have no top cell. A missing selected cell or reachable target
returns `MissingCell` (the first missing reference in inventory order). Unrelated
missing/cyclic components do not block extraction. Original parser admission and
the existing hierarchy/flattening error contracts are unchanged.

After building JS, `node tools/extract_cell.mjs SOURCE.gds CELL OUTPUT.gds` reads
the source once, completes extraction/validation, then exclusively creates a new
output file. It reads back the saved bytes and returns `gdsii-cell-extraction-v1`
JSON with the exact cell, ordered `kept_cells`, and actual source/output absolute
paths, byte lengths and SHA-256 hashes. Success exits0; request, input, query,
build, engine or output failures return JSON and exit2. Existing output paths,
including the source itself, are refused without overwrite. Deterministic
parse/query failures create no output. A late write/close/readback failure may
leave a partial or complete **new** file; it is reported as failure and is not a
transaction or automatic rollback. The parent directory must already exist.

The original example contains unrelated `unused`/`sibling` definitions, shared
`leaf`, selected `top`, three opaque records, properties and a 32-byte zero tail.
It exports exactly `[leaf,top]`, 534 ->324 bytes. The existing file consumers can
read the actual saved GDS directly:

```sh
node tools/inspect.mjs --catalog exported-top.gds
node tools/inspect.mjs --hierarchy exported-top.gds top
node tools/inspect.mjs --preflight exported-top.gds top 7 2 3 1
```

The last command deliberately exits3: three width2 rectangles violate width3,
with no spacing findings or skips. `node .ci/cell_extract.mjs` checks complete
independently hand-frozen streams, raw metadata, real physical-file receivers,
closed/missing/outside dependencies, empty cells and no-overwrite/error outcomes.
Its optional output directory must be new so prior evidence is retained.

Closure is defined only by the currently supported reference records. Opaque
extensions are retained without interpreting their dependencies; external
libraries, merge/rename, layer mapping, new formats and geometry/signoff
certification are outside this operation.

## Rename a cell and its supported references

`GdsLibrary::rename_cell(old_name, new_name)` returns a new checked library with
the selected STRNAME and every exact old-target SNAME changed together. Other
records remain in source order and keep their raw payloads: library name, TEXT
STRING, properties, opaque records, coordinates, placements and both raw UNITS
words are not textual search-and-replace targets. No cells are merged or removed.

```moonbit nocheck
let named = library.rename_cell("gate", "coreA").unwrap()
let bytes_for_receiver = named.to_bytes()
```

A missing old definition returns `MissingCell`. A real rename refuses an existing
destination definition and a name already used by unresolved known references;
otherwise those previously missing references could unexpectedly bind to the
renamed cell. For example, an unresolved reference to `future` prevents renaming
`gate` to `future`. Unrelated missing targets stay missing, and self/cyclic
references are renamed without flattening or repairing them. These query rules do
not tighten original source parsing.

New names use the existing checked ASCII/record profile, including its NUL and
size errors, with no additional historical32-character restriction. A real edit
uses `from_records`: offsets are recomputed and physical tail padding is omitted.
An existing old==new is instead a byte-identical no-op, including padding; an
absent name does not become valid by requesting a no-op. The source stays intact.

After building JS, `node tools/rename_cell.mjs SOURCE.gds OLD NEW OUTPUT.gds`
reads the source once, completes validation, then exclusively creates a new file
and reads it back. Success exits0 with `gdsii-cell-rename-v1`, old/new names,
`changed`, `updated_references`, ordered cell names, and source/output absolute
paths, byte lengths and SHA-256 hashes. Errors exit2; deterministic parse/query
failure creates no file and source/existing-target overwrite is refused. Late
write/close/readback failures may leave a partial or complete new target: this is
reported as an error, not a transaction or automatic rollback.

The new original sample renames `gate` to `coreA` in one definition and three
SREF/AREF uses, 454 ->438 bytes. LIBNAME, TEXT STRING, property value and two opaque
payloads still contain `gate`. Existing file receivers read the materialized GDS:

```sh
node tools/inspect.mjs --catalog renamed.gds
node tools/inspect.mjs --hierarchy renamed.gds die
node tools/inspect.mjs --preflight renamed.gds die 12 4 4 3
```

The last result is RectanglesClear for three selected boxes. Full hand-declared
streams and world rectangles, plus collision/capture/no-op/name-profile and
physical file outcomes, are checked by `node .ci/cell_rename.mjs` after the JS
build (optional fresh output directory). The unchanged parent finding comparison
is additional finding-level evidence, not a whole-geometry equivalence proof.

Only the existing definition/SREF/AREF naming semantics are interpreted. Names
embedded in unknown vendor extensions are preserved without inference. Batch
namespaces, merge, layer remapping, new formats and external adoption/signoff are
outside this operation.

## Linux native core consumers

With the pinned SDK/core configured in `MOON_HOME`, run:

```sh
moon test --target native
python3 .ci/native_core.py --expect-platform linux
```

The native gate builds `cmd/author`, `tests/record_rewrite` and `tests/native_core`,
verifies their ELF64 x86-64 executable headers, and directly runs the binaries
with an empty runtime PATH. Python checks the resulting GDS streams and property
rewrite against independently declared bytes, and REAL8 values against exact
rational expectations. DBU half-neighbors, overflow and malformed inputs are
included. The applications use the MoonBit core API and no Node host.

`_build/ci/native/` retains build logs, compiler `.core`/executable hashes (plus
generated-C hashes when retained by the SDK), the actual SDK identity, three
binaries, and expected/read-back original GDS files. Use a
fresh `--output DIRECTORY` for another local attempt to preserve previous evidence.
The Linux claim is limited to the CI's Ubuntu 24.04 x86-64 environment and pinned
SDK; downloaded-binary portability is not certified. The Node file wrapper keeps
its existing JS-only contract.

## Author an original rectangle pair

`cmd/author` is a runnable example of the existing `from_records` creation API.
Edit the two tuple arrays in `cmd/author/main.mbt` to supply rectangle corners in
DBU. Private sample helpers create record payloads, then `from_records` checks
the records and `to_bytes` serializes them. Library/cell names, layer7/type2,
unit values and original timestamps are fixed for a deterministic demonstration;
the sample helpers are not a new general writer API.

The example prints one `gdsii-author-v1` JSON object. `before` and `after` each
contain a byte-integer array and the existing preflight report; `comparison` is
their existing finding delta. JS and Wasm-GC produce the same object and GDS bytes.
The default before drawing has two width4 boxes with a gap6. The after drawing
narrows the second to width2: width3/spacing5 finds exactly one new width issue,
measured2 and shortfall1, while spacing remains clear.

```sh
moon build --target js
moon run cmd/author --target js | node tools/save_author.mjs authored-pair
node tools/inspect.mjs --preflight authored-pair/after.gds top 7 2 3 5
node tools/inspect.mjs --compare-tops authored-pair/before.gds authored-pair/after.gds 7 2 3 5
```

`save_author.mjs` consumes that JSON on stdin and writes `before.gds`/`after.gds`
inside the specified **new** directory; its parent must exist. It validates both
byte arrays before creating output, refuses an existing directory, returns the
saved paths as JSON and reports request/input/filesystem errors with exit2.
It materializes the sample's bytes; it does not certify report provenance or
perform geometry edits. The two review commands intentionally exit3 for the new
width issue. Use a fresh directory for another authored pair.

The helper also accepts a UTF-8 staged JSON file with one leading BOM. It removes
that initial marker before the same JSON/schema/byte validation; malformed JSON
still fails before output creation. This supports explicit Windows text-file
staging without changing the GDS bytes or adding automatic UTF-16 decoding.
For example, in PowerShell7, choose unused file/directory names:

```powershell
moon run cmd/author --target js | Set-Content -LiteralPath authored.json -Encoding utf8BOM
cmd /d /c "node tools\save_author.mjs authored-staged < authored.json"
```

Modern PowerShell normally uses UTF-8 without a BOM; `utf8BOM` is an explicit
choice here. [Microsoft's encoding reference](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-7.5)
describes that distinction. Direct author-to-helper piping remains available.

Source remains MIT; the original demonstration data is dedicated under
`testdata/LICENSE`. The demonstration uses DBU units of1, not a process recipe.
The existing selected-scope, raw-rectangle, comparison and no-signoff contracts
apply to caller-authored files exactly as they do to input files.

## Discovery and review library APIs

`catalog()` returns fresh typed `GdsCatalog` / `CatalogCell` / `LayerUsage` /
`CatalogReference` values. Counts describe definitions: an AREF is one reference,
with `instances = columns * rows`, and repeated references do not multiply layer
counts. Layer entries distinguish BOUNDARY/PATH/BOX/NODE/TEXT even when their
layer/type numbers coincide. Cells follow file order and layer entries follow
first occurrence. Missing references include the cell and zero-based element
index. `top_cells` means known cells without incoming references; cycles can
produce an empty list. Inventory does not validate cycles or run geometry rules.
It performs no hierarchy expansion or transforms, so large arrays and cyclic or
numerically unflattenable hierarchies can still be inspected. Parse errors fail.
The existing portable example prints this catalogue, a selected-root hierarchy
report, then its preflight result.

`hierarchy(cell)` returns a `HierarchyReport` for the chosen cell. Its
`reachable_cells` includes that cell and all known descendants in file order.
`layers` merges per-kind/layer/type definition counts over those unique cells:
a shared leaf is counted once, independently of reference/AREF multiplicity.
`references` preserves each reachable reference's original cell and element index;
`missing_references` excludes problems in disconnected cells. `cycle` is one
closed witness, chosen by the first DFS back edge in reference order, or `[]`.
The walk continues after finding a cycle so other reachable content remains visible.
A missing selected cell returns `MissingCell`; missing descendants and cycles
remain inventory findings. Returned arrays are fresh.

This iterative graph inspection does not apply transforms, expand arrays or use
the flatten depth limit. Its cost depends on file definitions/references/layer
entries, not on expanded instance geometry. The report helps choose selectors;
empty graph findings do not certify numerical flattening or DRC validity.

`preflight_cell(cell, layer, datatype, min_width, min_spacing, budget=100000)`
combines the existing flatten/selection/rectangle checks. Its `PreflightReport`
records cell, selectors, thresholds, DBU meters, selected/checked counts, skipped
geometry and sweep work. Each `PreflightIssue` includes the width/spacing rule,
required threshold, one/two world rectangle bounds and full instance source paths,
plus approximate measured and positive shortfall values in DBU. Graph, numeric
and expansion errors propagate. Negative selectors/thresholds are request errors.
The portable example now prints catalogue, hierarchy and this complete report.

| Status | Meaning in the selected raw-rectangle rule profile | `--preflight` exit |
| --- | --- | --- |
| RectanglesClear | At least one checked rectangle, no selected skips or violations | 0 |
| ViolationsFound | Checked violations exist; any skips are also retained | 3 |
| IncompleteGeometry | No checked violations, but selected geometry was skipped | 4 |
| EmptySelection | No known geometry on this layer/type in the selected cell | 4 |

Request/parse/graph/numeric errors exit 2. Old modes keep their existing exit
behavior. Work counters retain the core Int64 decimal-string JSON encoding.
File-read/build/engine failures also return one JSON `error` and exit 2.
Wrapper errors carry `stage` (`request`, `input`, `build`, `engine`), `code`, `message` and
relevant path/process context. Input errors preserve the OS code; an unavailable
compiled consumer gives `BUILD_UNAVAILABLE` and the build command. Existing
MoonBit parse/graph/numeric error JSON keeps its original structure. Failed or
invalid child output is not printed as a partial report. Results use natural
process exit with `exitCode` so pending output can drain.

Numeric arguments in positional, preflight and compare modes, including top-candidate
batches, must contain an explicit value.
Empty or whitespace-only selector/threshold tokens return
`request/EMPTY_NUMERIC_ARGUMENT` with the argument name and exit 2. Use an explicit
`0` for an intentional zero threshold. Existing nonempty numeric forms and omitted
defaults are retained; catalogue/hierarchy do not validate numeric arguments they
do not consume.

Shortfall is a rule deficit, not an edit instruction: overlapping boxes may need
more movement before a positive gap appears, and resizing shared child geometry
can affect multiple instances. Use the source/bounds to review a change and
recheck afterward. This API performs no geometry edits or process signoff.

A strict spacing violation can have a displayed Double distance that rounds to
the threshold. Shortfall uses the positive exact squared deficit divided by
`threshold + distance`, avoiding cancellation in that case. Classification remains
the existing exact integer predicate; displayed numerical values are approximate.

## Revision finding comparison

Run the two-file `--compare` command above after a change, or call the additive
`PreflightReport::diff(after)` on two library reports. The selected cell, layer/
type, rule thresholds and reported binary64 DBU-meter metadata must match;
incompatible profiles return `InvalidGeometry`. The CLI requires two paths and
uses one shared cell/rule selection. Shipped original CC0 revision files show a
width/spacing correction: two reported findings disappear and the after report
is RectanglesClear.

```moonbit nocheck
let before = before_library.preflight_cell("top", 7, 2, 3, 3).unwrap()
let after = after_library.preflight_cell("top", 7, 2, 3, 3).unwrap()
let changes = before.diff(after).unwrap()
```

Finding identity is rule plus exact world rectangle bounds, as a **multiset**.
Spacing pairs are unordered. Positional source paths and rounded diagnostic
values do not affect matching, so element reorder or hierarchy refactor does not
invent changes. Duplicate occurrences remain counted. `introduced` issues carry
after-side context; `removed` carries before-side context; `retained` is a count.
Arrays are fresh. Moving/reshaping an issue removes one geometry key and adds
another; there is no persistent object tracking or inference of a safe repair.
NoNewIssues can retain old violations, and different layouts can produce the same
findings. This compares supplied report findings, not complete geometry or report
provenance; malformed issue arity/threshold consistency is checked.

| Comparison status | Meaning | `--compare` exit |
| --- | --- | --- |
| NoNewIssues | Complete checked scope, no introduced findings; retained issues may remain | 0 |
| NewIssuesFound | Complete checked scope with introduced findings | 3 |
| IncompleteComparison | Either report skipped geometry or checked no rectangles; subset deltas remain visible | 4 |

Errors exit 2. A failure associated with one revision carries `error.side` as
before/after; profile failures use comparison. Engine-side errors retain the
original error under `error.detail`; wrapper input errors retain their stage/code/
path. Before/after statuses, checked counts and skipped findings are included so
disappearance under unchecked geometry cannot be mistaken for a repair result.
Original consumer modes and public signatures remain compatible.

## One-request top-candidate batches

Use `--preflight-tops file.gds layer datatype width spacing` to check every
catalogue top candidate in one invocation. Use `--compare-tops before.gds
after.gds layer datatype width spacing` for a per-candidate revision review.
There is no cell argument; omitted numeric values keep the 7/2/3/5 defaults.
Each file is parsed once. These are private consumer orchestration operations
over the existing public library methods; they add no library dependency or
public MoonBit API.

The JSON `batch` contains mode, aggregate status, candidate lists, `results` and
`counts`. Each result identifies its cell and carries the existing `preflight`,
`comparison` or `error` JSON. A candidate's graph, numeric, budget or comparison
error is retained and processing continues with later candidates. Global input/
parse/request failures remain top-level errors and exit 2.

Preflight follows catalogue file order. Comparison checks the union of before
top candidates followed by after-only candidates, matching the same cell name
in both files. `before_top` / `after_top` and both candidate lists expose root
membership changes. A cell that became a child can still be compared; a name
absent from either file returns its side-tagged `MissingCell` error, rather than
being treated as a repaired or empty selection. Other errors preserve the
existing before/after/comparison side context.

| Aggregate status | Meaning | Exit |
| --- | --- | --- |
| ErrorsFound | At least one candidate errored; other results remain visible | 2 |
| Incomplete | An IncompleteGeometry/EmptySelection/IncompleteComparison result, or no candidates; no errors | 4 |
| IssuesFound | A ViolationsFound/NewIssuesFound result; no status-level incomplete result or error | 3 |
| Passed | Nonempty scope with every result RectanglesClear/NoNewIssues | 0 |

Precedence is errors, incomplete, issues, then passed. Counts describe root
results: `passed`, `failed` (violations/new findings), `incomplete`, `errors`;
they do not count individual findings. A passed comparison can still retain old
issues under its existing NoNewIssues contract.

`coverage.complete` independently describes selected raw-rectangle coverage. It
is true when there is at least one candidate and every candidate has checked
rectangles, no selected skips and no error; comparison requires this on both
sides. `coverage.unchecked_cells` lists each root with an error, zero checked
rectangles or selected skips once, in result order. With no candidates, complete
is false and the list is empty. Global input/request/parse failures keep their
top-level error response because candidate scope could not be established.

Status/count categories are preserved: a preflight candidate with both a width
violation and a skipped PATH remains ViolationsFound/failed, so the aggregate may
be IssuesFound (exit 3) while coverage.complete is false. `counts.incomplete` is
a status category, not the count of every partially checked candidate. Conversely,
coverage.complete=true can coexist with violations or retained baseline issues;
it is not an all-clear or physical-signoff flag.

```sh
node tools/inspect.mjs --preflight-tops examples/multi-top-partial.gds 7 2 3 3
```

This original CC0 example has one width issue plus a skipped PATH in `mixed`, and
a clear `healthy` candidate. It exits 3 with passed=1, failed=1, incomplete=errors=0
and `coverage: {"complete": false, "unchecked_cells": ["mixed"]}`. Batch JSON
adds this coverage object; existing fields, per-root payloads and exits remain.
Consumers that compare entire JSON strings need to account for the additive field.

The shipped CC0 multi-top example has `repair`, `regression`, `stable` candidates.
The compare command above reports one removed width issue, one new spacing issue
and an unchanged clear candidate: passed=2, failed=1, incomplete=errors=0, exit 3.
It demonstrates that a repair in one object does not hide a regression in another.

Each candidate is checked independently with the default expansion budget 100000
or the explicit final budget. Top cells are not overlaid and no cross-top spacing
is checked. Candidate
discovery is not whole-library coverage: isolated cyclic components may have no
top candidate. An empty candidate list produces Incomplete, not vacuous success;
use selected-cell/hierarchy modes to inspect other definitions. Existing raw
rectangle, output-buffer, numerical and no-signoff limits apply.

## Saved multi-profile review plans

Use `--review-plan SOURCE.gds PLAN.json` to hand over several named checks of one
cell in one result. The UTF-8 JSON plan accepts one initial BOM and has this shape:

```json
{
  "schema": "gdsii-rectangle-review-plan-v1",
  "cell": "top",
  "budget": 100000,
  "profiles": [
    { "id": "metal7", "layer": 7, "datatype": 2, "min_width": 3, "min_spacing": 5 }
  ]
}
```

Cell and IDs are nonempty strings; IDs must be unique. Profiles are ordered and
nonempty, with all four explicit nonnegative INT32 selectors/rules in input DBU.
Unknown fields and malformed profiles reject the whole plan before source parsing
or geometry evaluation. The optional positive INT32 budget defaults to 100000 and
resets for each profile, counting all visited instances/emitted shapes before
selection. No geometry is truncated on exhaustion.

The frontend reads each file once, then passes both snapshots to one engine
request. The engine validates the entire plan, parses the GDS once and reuses the
library for existing `preflight_cell` calls. Flattening is still repeated per
profile. The result schema is `gdsii-rectangle-review-result-v1`: `source` and
`plan` contain absolute paths, raw byte lengths and SHA-256 fingerprints (including
any plan BOM/whitespace). `review` echoes the cell, resolved budget and profiles,
and returns one ordered `results` entry per ID, containing `preflight` or `error`.
Global plan/parse failures return one top-level error without partial results.

| Review status | Exit | Meaning |
| --- | --- | --- |
| ErrorsFound | 2 | At least one profile failed; later profiles still have results |
| Incomplete | 4 | No profile errors, but some profile has zero checked rectangles or skipped geometry |
| IssuesFound | 3 | All requested coverage checked; rectangle violations found |
| Passed | 0 | All requested coverage checked and clear |

This precedence is specific to review plans: even `ViolationsFound` plus skipped
geometry yields aggregate `Incomplete`. Counts retain existing per-profile status
classification, so `counts.failed` can be positive while `counts.incomplete` is
zero and `coverage.complete` is false. `coverage.unchecked_profiles` lists every
unchecked/error ID in order. Existing commands retain their status/exit contracts.

The runnable example checks four profiles over four rectangles and one PATH. It
exits4 with passed=1, failed=1, incomplete=2, errors=0; `path-layer` and `unmapped`
are unchecked. The narrow metal7 rectangle has width2 against threshold3.
After building JS, `node .ci/review_plan.mjs` verifies independent Stream bytes,
known geometry and snapshot handoff, including an external disk replacement that
forwards the original request to the real engine. Use a fresh optional output
directory to retain another attempt.

Fingerprints identify the bytes actually reviewed, not a simultaneous filesystem
transaction, authorship signature or current disk contents after completion.
Coverage applies only to requested profiles and supported raw rectangles; it
does not certify unrequested layers, stroked paths, merged polygons or signoff.

## Format and hierarchy profile

The format reference is Calma **Stream Format Manual, Release 6.0 (February 1987)**.
This is a documented reference profile, not a claim of every historical tape feature.

| Records | Behavior |
| --- | --- |
| HEADER/BGNLIB/LIBNAME/UNITS/ENDLIB, BGNSTR/STRNAME/ENDSTR | Typed framing, mandatory-field, scope and duplicate-name checks |
| BOUNDARY/BOX | Closed coordinate rings retained; only verified simple boxes enter DRC |
| SREF/AREF, STRANS/MAG/ANGLE/COLROW/XY | Nested expansion; reflection, uniform positive magnification, arbitrary angle, absolute magnitude/angle, skew array vectors, singleton arrays |
| PATH/WIDTH/PATHTYPE/BGNEXTN/ENDEXTN | Centerline, width and end-extension data retained/transformed; negative WIDTH is absolute; arbitrary path stroking is not performed |
| TEXT/PRESENTATION/STRING, NODE/NODETYPE | Location and available metadata retained; not treated as filled rectangles |
| ELFLAGS/PLEX/PROPATTR/PROPVALUE | Raw records retained; property pairing checked |
| Legacy library metadata and unknown records | Raw preservation; no implied semantic evaluation of unknown extensions |
| Zero padding after ENDLIB | Preserved; nonzero trailing data rejected |

Malformed lengths, data types/alignment, required fields, attribute scope/order,
ring closure and element counts return structured errors. Dates and every legacy
metadata value are not exhaustively semantically validated. Unknown records do not
turn this reader into an evaluator for unknown geometry extensions.

AREF step vectors are `(P1-P0)/columns` and `(P2-P0)/rows` in the parent cell's
coordinates. They are not transformed twice. Absolute magnitude overrides inherited
scale; absolute angle is interpreted in world axes; reflection parity composes XOR.
GDS MAG is uniform, so no anisotropic scaling API is invented.

Coordinates remain binary64 until the final output DBU conversion: nearest integer,
half cases away from zero; values outside signed INT32 after rounding fail. Reference
cycles and dangling cells fail explicitly. The budget counts visited instances and
emitted shapes; a depth cap of 256 also bounds recursion.

Inherited MAG stores a binary64 significand and a separate integer exponent.
An intermediate scale outside binary64's exponent range can recover through a
later relative or absolute MAG; it is not prematurely replaced by zero/infinity.
Coordinates/translations and final numeric metadata remain binary64, with normal
IEEE subnormal rounding. This does not provide arbitrary-precision coordinate
cancellation or remove the INT32 output bound.

## REAL8

`Real8Raw::from_bytes` / `to_bytes` preserve every eight-byte word, including
noncanonical and zero encodings. `to_f64` converts the base-16 exponent/56-bit
fraction to nearest-even binary64; a nonzero value's conversion relative error is
below 2^-52. `from_f64` exactly encodes finite binary64 values within the normalized
REAL8 range, canonicalizes zero, and rejects NaN/Inf and out-of-range magnitudes.

These APIs deliberately have different contracts: raw `4180000000000004` rounds
to Double 8 and re-encodes as `4180000000000000` (four source fraction LSBs lost).
The largest REAL8 rounds up to a Double outside the REAL8 encoding range. Preserve
the raw word for byte-exact rewrites; do not route it through Double. Relative error
is not a meaningful contract for zero or for a failing encoding operation.

## Rectangle rules

Inputs are **raw unmerged** positive-size boxes on one selected layer/datatype.
Duplicate instances remain distinct. Width is `min(max_x-min_x, max_y-min_y)`.
Spacing is Euclidean set distance: with nonnegative x/y gaps, `sqrt(dx²+dy²)`.
Touch/overlap has distance zero. A violation uses strict `< threshold`; equality
passes. Thresholds must be nonnegative INT32. Geometry arithmetic widens before
subtracting; the strict squared-distance predicate avoids Int64 addition overflow.

The sweep uses an augmented AVL y-interval index and x expiration events.
For N boxes, C square-halo candidate pairs, V index-node visits and K reported
violations, the implemented bound is **O(N log N + V + C + K)** and space O(N+K).
Counters expose C and V. This is not an unproved output-optimal O(N log N+K)
claim: Euclidean corner rejection can make C larger than K.

Collinear monotone redundant vertices are allowed on otherwise simple boxes.
Concave, diagonal, degenerate, retraced and self-crossing shapes, PATH/TEXT/NODE
and other selected non-box geometry produce individual skip findings. General
polygon/holes/union, path stroking, cross-layer rules and foundry signoff are outside
this first release.

## Independent validation and sources

Black-box tests embed actual original gdstk-written GDS inputs, exact INT32 output
from its flatten/write path, hand-derived integral absolute-transform fixtures,
and independent exhaustive Python unbounded-integer DRC expectations. Numerical
tests cover the four-LSB counterexample, canonical constants, zero/range failures,
negative half cases and DBU bounds. Error tests cover malformed streams,
missing/cyclic references, expansion limits, retention and skip behavior.

For an independently installed **gdstk 1.0.2**:

```sh
python -m pip install gdstk==1.0.2
moon build --target js
python tools/verify_reference.py
```

That script runs the real Node file consumer against gdstk and an exhaustive
distance oracle, including a mixed file with boxes, triangle, PATH and label.
gdstk 1.0.2 and KLayout 0.30.12 both report unsupported absolute STRANS flags;
their output is not used as the truth for those flags. Floating-point behavior at
half-grid boundaries is checked against actual serialized gdstk output, not ideal
cardinal-angle arithmetic. A finite corpus proves the listed cases, not universal
bit-identical behavior across every floating-point transform/platform.

See `THIRD-PARTY.md` and `testdata/LICENSE` for source and fixture rights.

### DBU half-neighbor repair (2026-10-28)

DBU rounding compares the fractional remainder with 0.5 before incrementing the
integer part. Adding 0.5 first is incorrect for binary64 `0x3fdfffffffffffff`
(`0.5 - 2^-54`): that addition rounds to 1.0. Both signs now correctly round to
integer zero, including coordinates reached through `flatten_cell`.

This repair was checked with 34 new focused tests on each of JS and Wasm-GC,
10 affected prior regressions on each target, and 6 targeted native tests.
Exact Fraction/integer expectations cover adjacent half-grid and REAL8 encoding
boundaries, nested STRANS/AREF combinations and rectangle spacing extrema.
Two original GDS files through the actual Node consumer also match gdstk 1.0.2's
serialized INT32 coordinates. These counts describe this repair's selected checks;
unchanged historical suites were not rerun in full.

### Parser state repair (deep06, 2026-10-28)

Libraries with zero cells need only the five mandatory library records and now
parse without a dummy metadata record. Known header records inside elements and
known element attributes outside elements return structural errors at the exact
record offset. Unknown extension records, including repeated kinds, retain their
original ordering and bytes; known-field uniqueness and property pairing still
apply. Six new state-focused tests pass on JS, Wasm-GC and native, with four
selected prior parser/hierarchy controls on each portable target. Six actual file
consumer cases cover empty/valid attributed inputs, misplaced records and unknown
extensions. Prior numerical/DRC suites are reused rather than claimed as rerun.

### Rotation and metadata repair (deep07, 2026-10-28)

Flattening reduces an ANGLE's exact raw REAL8 value modulo 360 before converting
its remainder to Double, and composes bounded world orientations in `(-180,180]`.
This avoids losing a large angle's fractional bits or a relative child's rotation.
Raw records and the original numeric `Placement.angle` in `cells()` are retained;
`FlatShape.angle` describes the resulting canonical world orientation.

Transformed width, end extensions and magnification must be finite binary64
values. Unrepresentable output metadata returns `InvalidNumber` with its field
and instance source, rather than a successful result containing infinity.
Representable large values, absolute PATH width and absolute TEXT magnitude
remain supported. This is an output representation error, not a raw-reader limit.

The repair passes 16 focused tests on each of JS, Wasm-GC and native, 25 affected
prior transform controls on each portable target, and 7 actual file-consumer
cases. Angle truth uses exact Fraction remainders and high-precision algebraic
matrix calculations; unsupported external large-angle outputs are not used as
an oracle. Earlier unchanged parser/DRC suites were not rerun.

### MAG range repair and catalogue extension (deep08, 2026-10-28)

Five relative factors of 2^-250 followed by five of 2^250 now recover the identity;
the reverse order also works. Zero origins and zero metadata stay zero under a
wide inherited scale. Absolute reference/TEXT magnitudes can replace that scale.
Final finite/subnormal metadata is rounded only when emitted; actual output
overflow still reports the existing numerical errors. Raw data is preserved.

The 16 new scale tests and 7 catalogue tests pass on each of JS, Wasm-GC and
native. Each portable target also passes 42 related prior controls. Consumer
checks cover 16 scale files, 9 catalogue cases (including gdstk info/root comparison
on the original demo), and 9 unchanged preflight JSON requests. Both portable
examples run. Older unchanged parser/DRC collections were not rerun in full.

Catalogue follows an established CAD inspection workflow, also available through
[gdstk gds_info](https://heitzmann.github.io/gdstk/library/gdstk.gds_info.html).
The contribution here is portable native MoonBit integration, explicit per-cell
and per-kind definition counts and unresolved-reference locations in the same
byte-preserving/preflight library. It adds no external runtime dependency.

### Selected-root hierarchy discovery (deep09, 2026-10-28)

The catalogue's direct top-cell layer table can be empty when all geometry is
in referenced cells. The new hierarchy report closes that discovery step without
changing the catalogue's definition-count contract. Disconnected missing targets
and cycles are excluded; shared descendants are deduplicated, while separate
reference definitions remain visible. A 288-cell chain and a 32767x32767 AREF
are inspected without requiring successful flattening.

Thirteen new graph/API tests pass on each of JS, Wasm-GC and native. Actual
consumer checks cover 15 scenarios, three independent gdstk dependency comparisons,
and the complete catalogue -> root -> reachable layer -> preflight path. Nine old
preflight requests and two old catalogue cases retain their sealed prior JSON
responses. Both portable examples run. Parser, numeric, transform and rectangle
implementations are unchanged and their earlier passing evidence is reused.

Recursive dependency discovery is also available in established tools such as
[gdstk Cell.dependencies](https://heitzmann.github.io/gdstk/library/gdstk.Cell.html).
This API combines it with root-local definition layers, missing-reference
locations and a cycle witness in the portable MoonBit reader/preflight workflow.

### Source-located preflight (deep10, 2026-10-28)

Twenty-three new API cases pass on each of JS, Wasm-GC and native. Independent
unbounded-integer and 100-digit Decimal expectations cover strict equality,
overlap/touch/diagonal spacing, a one-squared-unit spacing deficit near INT32_MAX,
coverage states, nested instance locations, non-unit DBU, range/error paths and
raw/report ownership. Twenty-four actual consumer scenarios check the four
statuses and CLI exit codes; the full discovery-to-selected-preflight workflow
finds two instances of one child definition. Seventeen old-mode responses remain
compatible. Both portable examples run. Existing core rule/format/transform/graph
implementations and their previously passing suites are reused unchanged.

### CLI failure responses (deep11, 2026-10-28)

Missing input, directory input and a fresh source checkout without inspect.js
previously yielded empty stdout, exit 1 and an uncaught Node/module stack. They
now return structured failure JSON and exit 2, with a build hint when appropriate.
Nine valid/status/known-error controls, including Chinese/spaced paths and all
four modes, retain exact stdout/stderr/exit results. Five isolated child-protocol
fault checks cover partial nonzero output, invalid JSON/shape/status and the
existing 64 MiB buffer limit. These injections verify the wrapper boundary, not
alleged layout defects. Node syntax and 17 actual consumer checks pass on Windows
Node v24.11.0. MoonBit source, public interface and compiled artifacts are unchanged;
their already passing JS/Wasm-GC/native evidence is reused without rebuilding.

### Blank script arguments (deep12, 2026-10-28)

The CLI previously converted an empty/whitespace numeric token to zero: six
focused requests silently succeeded and four became empty selections. The new
request check rejects those ten cases, including a nonbreaking space, before
file/build work. Twenty legitimate/default/unused-argument/prior controls retain
exact stdout/stderr/status, including explicit zero and prior numeric forms.
Node syntax and all 30 actual CLI checks pass. The numerical/rule implementation,
public API and compiled artifacts are unchanged; earlier core suites are reused.

### Revision comparison (deep14, 2026-10-28)

Twenty-six new API tests pass on JS, Wasm-GC and native. Independent integer/
100-digit Decimal finding models and tuple Counters cover sixteen paired revision
cases, plus profile errors, malformed issues, diagnostic rounding and ownership.
Thirty actual two-file CLI/error/example scenarios, one raw request-protocol check
and 33 old-mode compatibility cases validate the review workflow. The earlier
round13 transport scenarios are not rerun.

General diff tools already exist, including
[moonbit-community/diff](https://github.com/moonbit-community/diff),
[bobzhang/difflib](https://mooncakes.io/docs/bobzhang/difflib) and
[KLayout LayoutDiff](https://www.klayout.de/doc/code/class_LayoutDiff.html).
This feature is the narrower native MoonBit preflight finding multiset/profile
operation; it adds no external runtime dependency or general layout XOR engine.

### Multi-top consumer workflow (deep16, 2026-10-28)

Thirty-eight new actual CLI scenarios and four request/engine-protocol checks
cover mixed per-candidate outcomes, continuation after errors, empty/rootless
scope, root union/membership changes, comparison profiles and aggregate exits.
Known integer geometry and authored reference graphs supply the expectations;
four valid root sets also match gdstk. Nine representative existing-mode controls
retain exact stdout/stderr/exit results. JS strict check/build, Node syntax,
formatting and public-interface identity are checked. Existing core source and
public exports are unchanged; prior portable/native suites and round14/15 pairs
are reused without rerunning them.

Root enumeration and scripted batch DRC are established workflows in
[gdstk Library.top_level](https://heitzmann.github.io/gdstk/library/gdstk.Library.html)
and [KLayout DRC runsets](https://www.klayout.de/doc/manual/drc_runsets.html).
This consumer integrates the project's existing rectangle/report contracts in
one request; it is not a replacement for KLayout's general DRC engine.

### Independent batch coverage (deep17, 2026-10-28)

Four new baseline consumer combinations confirmed normal budget continuation and
cycle-to-top membership semantics, and exposed incorrect complete-scope wording
for same-candidate violations plus skips. The wording is corrected; the existing
status/count classification is preserved. The additive coverage summary reports
the selected-scope distinction directly without changing the public library API.

Nine focused consumer scenarios pass, with independent integer geometry/authored
graphs and five exact prior-output controls after removing only the coverage
object. They cover mixed skips/issues, shared-leaf budget failure, cyclic before
definitions, complete coverage with findings, empty/zero-checked scopes and ordered
unchecked names. JS strict check/build, format and generated interface identity
pass. The full round16 suite and prior portable/native suites are not rerun;
one sealed comparison is used specifically to verify the new coverage field.

### Editable native authoring workflow (deep19, 2026-10-28)

The new example runs on JS and Wasm-GC with identical output. Independent Python
struct encoding checks each complete original GDS stream; four materialized files
are read back and two unique layouts also match gdstk geometry/layer/type/units.
Nine consumer cases cover materializing both backend outputs, three existing file
review commands and four necessary error/no-overwrite boundaries. Strict checks,
JS build, Node syntax, formatting and public-interface identity pass. Core/public
APIs and all existing commands are unchanged; old passing suites are reused.

Rectangle creation/export is already demonstrated by
[gdstk Getting Started](https://heitzmann.github.io/gdstk/gettingstarted.html).
This is a native MoonBit developer example connecting the existing record-creation
and review APIs, with no added package dependency or new writer-engine claim.

### Staged author JSON compatibility (deep20, 2026-10-28)

PowerShell7.6.5 utf8BOM staging reproduced an additional interoperability gap:
the original JSON worked without its BOM, while the staged file failed at input.
The materializer now accepts a single initial UTF-8 BOM. Three focused consumers
and Node syntax pass; four saved files match the exact sealed original bytes.
Malformed JSON after a BOM still creates no output directory. All MoonBit source,
public interfaces and compiled identities remain unchanged, and round19's passing
dual-target/independent-structure/gdstk/nine-case evidence is reused, not rerun.
The new-directory/no-overwrite and nontransactional late-I/O boundary remain.
