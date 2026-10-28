# Sources and rights

- Calma GDSII Stream Format Manual, Release 6.0, February 1987, B97E060:
  [archival catalogue](https://bitsavers.org/pdf/calma/),
  [reference mirror](https://manuals.plus/m/2901807444a6f9ba2d59bb99e65895dc1e1abe0b4b2897563a8937fedcb523a5.pdf).
  Its original notice restricts copying. The manual is referenced, not bundled,
  not relicensed and not described as an open licensed dataset.
- [gdstk](https://github.com/heitzmann/gdstk): Boost Software License 1.0.
  Source review pinned at 1099be134da34d4afd9e5fb1f4f0dbae9ef4c17a;
  runtime reference gdstk 1.0.2 (Python), NumPy 2.5.4.
  Used for external reference generation/consumer validation; its implementation
  is not copied or linked into this native MoonBit library.
  Its documented gds_info/top_level inspection workflow was also compared for
  the catalogue extension: [gds_info documentation](https://heitzmann.github.io/gdstk/library/gdstk.gds_info.html).
  [Cell dependencies documentation](https://heitzmann.github.io/gdstk/library/gdstk.Cell.html)
  informs the established workflow and supplies an independent hierarchy-set
  comparison on supported acyclic fixtures.
  [Library.top_level documentation](https://heitzmann.github.io/gdstk/library/gdstk.Library.html)
  was reviewed for the multi-top consumer workflow; four new valid candidate
  sets were independently checked with the already installed gdstk 1.0.2.
  [Getting Started authoring/export example](https://heitzmann.github.io/gdstk/gettingstarted.html)
  demonstrates the established create-rectangle/write-GDS workflow in Python/C++.
  The deep19 native authoring example uses this project's existing from_records;
  gdstk independently reads the two original emitted layouts. No gdstk writer
  implementation is copied into the sample or linked at runtime.
- [KLayout](https://github.com/KLayout/klayout), GPL-3.0 license text:
  0.30.12 was queried externally. Its explicit absolute-transform warning made
  those outputs unsuitable as an oracle. No KLayout implementation is included.
  [Cell called_cells documentation](https://www.klayout.de/doc/code/class_Cell.html)
  was consulted for recursive dependency discovery; no new KLayout runtime
  comparison is claimed for the selected-root hierarchy feature.
  [DRC reporting documentation](https://www.klayout.de/doc/manual/drc_basic.html)
  was consulted for named/localized findings. The raw unmerged rectangle profile
  here is not claimed equivalent to KLayout's merged/general-polygon rules.
  [LayoutDiff documentation](https://www.klayout.de/doc/code/class_LayoutDiff.html)
  was compared for the established revision-review workflow; this project's
  report-finding delta is not a full KLayout geometry-diff replacement.
  [DRC runsets](https://www.klayout.de/doc/manual/drc_runsets.html) provide
  established cell/source selection and reporting workflows. The multi-top
  consumer is narrower raw-rectangle/report orchestration, not novel batch DRC
  or a KLayout rule-semantics replacement.
  [DRC global functions](https://www.klayout.de/doc/about/drc_ref_global.html)
  documents report output and separate warnings/logging. The deep17 coverage
  summary derives solely from this project's checked/skipped/error reports;
  separate coverage and findings are not claimed as a novel reporting concept.
- [moonbit-community/diff](https://github.com/moonbit-community/diff) and
  [bobzhang/difflib@0.2.0](https://mooncakes.io/docs/bobzhang/difflib), Apache-2.0:
  their official sequence/text comparison documentation was reviewed as nearby
  alternatives. Neither implementation is copied, linked or added as a dependency.
- [C draft N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
  section 7.12.9.7, establishes the half-away semantics of lround; no draft bundled.
- Optional Node file consumer: built-in API behavior was checked against
  [Node v24.11.0 fs](https://nodejs.org/download/release/v24.11.0/docs/api/fs.html),
  [child_process](https://nodejs.org/download/release/v24.11.0/docs/api/child_process.html)
  and [process](https://nodejs.org/download/release/v24.11.0/docs/api/process.html)
  documentation for structured I/O failures and output-draining exitCode. No Node
  implementation is vendored and no MoonBit dependency was added.
- [RFC8259 section8.1](https://www.rfc-editor.org/rfc/rfc8259.txt) permits leading
  BOM tolerance for JSON interoperability; this is optional parser behavior.
  [PowerShell character encoding](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-7.5)
  documents explicit UTF-8 BOM staging and the modern no-BOM default. Deep20
  reproduces the staged-file case on PowerShell7.6.5 without changing global
  encoding settings or broadening GDS/geometry support.
- [moonbitstack/moonjson@0.4.0](https://mooncakes.io/docs/moonbitstack/moonjson),
  Apache-2.0, exposes byte-input BOM handling, and
  [strip-bom](https://github.com/sindresorhus/strip-bom), MIT, documents this
  established normalization practice. Neither package is installed or copied;
  the materializer uses one native string operation before its existing parser.
- Mooncakes nearest libraries reviewed: cn-xjr/moongeokit@0.3.0 (Apache-2.0),
  BigSaltyMan/moonclip@0.4.0 (BSL-1.0), Mgk789a/moonbit-gerberkit@0.2.4
  (Apache-2.0). Their generic geometry/DFM functions are not claimed as novel.
  This library's contribution is its GDS record/numeric/hierarchy contract,
  source paths and portable preflight integration. None is a runtime dependency.
  The live moongeokit 0.3.0 registry/API review for deep16 confirms generic
  geometry/spatial-index batch mutations, not the same GDS root/report workflow;
  [registry documentation](https://mooncakes.io/docs/cn-xjr/moongeokit).
  A bounded search did not confirm another matching MoonBit batch-preflight
  module; this is not an ecosystem-wide absence or novelty claim.
  The deep19 current registry review also distinguishes its generic GeoJSON
  authoring/export from this GDS record-creation example. A bounded writer query
  did not confirm a matching substitute; no ecosystem absence claim is made.
- The repository's synthetic GDS files and expected coordinates/distances were
  authored for this project with gdstk as a writer; see testdata/LICENSE. No
  Calma sample drawing, foundry PDK or research layout is redistributed.

Source code is MIT under the root LICENSE. That license does not extend to the
external references, tools, or unrelated layout inputs supplied by users.
