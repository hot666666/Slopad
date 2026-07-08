# AGENTS.md

This file is the entry point for agents working in the Slopad repository. Use
`README.md` for the current structural map, this file for terminology and responsibility
criteria, `ADR/` for durable architecture decisions, and `docs/ROADMAP.md` for the
development direction.

## Project Overview

`SlopadEngine` is a headless native block editor engine written in Swift. It is aimed at
Notion/Craft-style block editor hosts. The document is a block tree, and editor semantics
belong to the engine. Platform code supplies native input, drawing, and text layout
backends.

The current platform path is macOS AppKit + TextKit2. AppKit is an adapter, not the engine
model. `SlopadAppKitUI` translates AppKit callbacks into engine input values and applies
the layout/render/hit-test/reveal/redraw facts returned by `EditorSession` through AppKit
drawing plus focus/scroll synchronization.

SlopadEngine owns block document state and block identity, caret/text/block selection,
keyboard/pointer/native command/IME composition semantics, command application,
undo/redo, semantic change projection, block layout orchestration, hit testing, reveal
geometry, and render snapshots.

The engine does not own platform widgets. Concrete views such as `NSTextView` or
`UITextView` are not engine targets. A native surface collects OS callbacks, forwards them
as engine input, and draws engine snapshots. `SlopadEngine` decides semantic behavior such
as caret/selection, marked-text lifecycle, insert/delete/native command intent, block
transitions, and shortcut normalization.

Markdown is not the canonical model. The canonical model is a tree-capable block store.
Markdown is only import/export format or input shortcut syntax.

## Document Index

- `README.md`: architecture map, package products, and AppKit UI package usage.
- `ADR/`: durable architecture decision records.
- `docs/ROADMAP.md`: completed milestones, next product/performance direction, and open
  risks.
- `docs/LOOP_REQUEST_TEMPLATE.md`: copy-paste template for bounded loop requests.
- `docs/LESSONS_LEARNED.md`: past cleanup/refactor failure patterns. It is not the source
  of truth for current structure.
- `Benchmarks/Baselines/README.md`: checked-in CSV baseline index.

Do not treat state-management or cleanup-campaign plan/review/goal/handoff documents as
sources of truth.

## Core Layers

- `SlopadEngine`: UI-facing facade for platform hosts. `EditorSession` receives input,
  live IME/composition overlays, render, hit-test, reveal, and redraw requests, calls
  `EditorModel` and `BlockLayout`, and returns results consumed by UI code.
- `SlopadCoreModel`: public vocabulary interpreted by both hosts and engine layers, plus
  package canonical `Document`/`Block` values. It is not a dump for internal projections
  or generic helpers.
- `SlopadEditorModel`: owns the storable canonical `Document`, `Selection`, `Command`,
  `Transaction`, `History`, and semantic `Change`. It must not import
  `SlopadBlockLayout`, and it must not contain live composition, layout, y offsets,
  TextKit rects, or render damage.
- `SlopadBlockLayout`: manages block heights/y positions, visible ranges,
  reveal/hit-test geometry, and layout snapshots. It must not import
  `SlopadEditorModel`; it uses `TextLayout` and `BlockHeightIndexStorage` as internal
  axes.
- `TextLayout`: the axis for the `BlockTextLayoutProtocol` backend seam and layout cache.
  It covers line fragments, caret/selection rects, and text hit-testing, not only height.
  Do not rename it to `textMeasurer`.
- `BlockHeightIndexStorage`: owner of block height/y prefix-sum storage. The default
  implementation uses `PrefixSumRedBlackTree`.
- `SlopadDataStructure`: pure data structures with no editor concepts.
- `SlopadTextKit`: Apple TextKit2-based block text layout/rendering backend. It does not
  own native view/input host types or canonical editor state.
- `SlopadAppKitUI`: reusable macOS AppKit adapter. It provides AppKit key/pointer/IME
  callbacks, scroll/focus sync, TextKit drawing, and a block-kind chrome interface, but
  it does not own engine semantics or canonical state.
- `SlopadDebugApp`: macOS reference/debug host. Debug-only state such as the debug HUD,
  scenario driver, screenshot capture, and state assertions stays out of the reusable UI
  package.
- `SlopadUIBenchmarkApp`: AppKit UI benchmark harness. Frame loops, CSV output, and forced
  display flushes stay out of the reusable UI package.

`DataStructure` is not a product layer. `PrefixSumRedBlackTree` remains a pure foundational
data structure, while the y/height domain belongs to `BlockHeightIndexStorage`.

`EditorModel` does not call or own `BlockLayout`. `EditorModel` state/change facts are
used by `Session` when it builds `BlockLayout` requests.

## Terminology and Decision Criteria

- `SlopadCoreModel` contains only the public vocabulary needed by host contracts, backend
  seams, and package canonical values. It is not a fallback bucket for projections or
  helpers that became inconvenient during deletion experiments.
- `Document`/`Block` are storable canonical block tree values. The host-facing public
  model is limited to values needed to read the Session contract or backend seam, such as
  `EditorBlockInput`, `EditorInputEvent`, `EditorSelection`, and geometry/layout seam
  values.
- A range inside one block is `Text Selection`; selection of one or more visible blocks is
  `Block Selection`; no selection is `Inactive Selection`. Current multi-block work is
  modeled as block selection, not cross-block text ranges.
- IME/marked text is not canonical document content. It is a live composition overlay in
  Session runtime state. Ordinary editing exits such as focusing another block, entering
  block selection, or clicking empty space commit composition first. It is discarded only
  when native input sends an explicit cancel.
- `BlockLayout` owns visible order, y/height, hit/reveal geometry, marker projection, and
  layout invalidation. `EditorSession` assembles UI render descriptors and host-facing
  snapshots.
- `TextLayout` does not mean height measurement only. It includes line fragments,
  caret/selection rects, and text hit-testing, so keep the `textLayouter` name and do not
  shrink it to `textMeasurer`.
- An owner is the layer with final authority over the invariant and mutation rule for a
  meaning. A projection is a derived read/display/calculation result from canonical state
  and does not replace canonical state.
- Add a new type only when it carries a real invariant, reuse point, test surface, or
  cross-layer vocabulary. If deleting it pushes complexity into `SlopadCoreModel`,
  `Session`, test support, or multiple call sites, the deletion did not succeed; the
  interface was wrong.

## Work Loops

- Name the repeated task or risk type first, for example structure change, bug fix,
  performance change, or AppKit adapter surface cleanup.
- Before editing, write at least three completion criteria. They should say which
  observable behavior, owner/interface boundary, test, build, or benchmark will prove
  completion.
- Structure-change loop:
  `owner decision -> type inventory -> deletion/merge/access-shrink experiment ->
  deletion test -> place surviving types by owner/read intent -> verification -> durable
  doc update`.
- Bug-fix loop:
  `symptom -> canonical owner -> why tests missed it -> focused test -> fix -> full
  verification`.
- Performance-change loop:
  `hot-path hypothesis -> 100/1000/10000 benchmark -> counter check -> CSV/doc update ->
  regression risk record`.
- A one-off bug should become a test. A twice-repeated mistake becomes a candidate rule in
  this file. Only structural failure patterns should be added to `docs/LESSONS_LEARNED.md`.
- If the same issue still fails after three fix attempts, stop editing and report the
  candidate causes, failed attempts, remaining uncertainty, and next check.

## UI/UX Feature Workflow

- UI/UX work must verify both visible AppKit behavior and the owning engine behavior; a
  surface change alone is not completion.
- Use `SlopadDebugApp` and the helpers in `scripts/` for real input, focus, selection,
  IME/composition, scrolling, reveal, hit-test, screenshot, and state-regression checks.
- Use `SlopadUIBenchmarkApp` when changes may affect frame time, layout work, redraw,
  text layout cache behavior, drag/reorder, or large-document interaction.
- Separate ownership before fixing UI bugs: AppKit callback/drawing glue belongs to
  `SlopadAppKitUI`; semantic editing, selection, composition, hit-test, reveal, and layout
  orchestration belong behind `EditorSession`.

## Working Principles

- Run `git status --short` before making changes so user-owned uncommitted work is
  visible.
- Before structure/engine/UI package changes, read `README.md`, relevant ADRs,
  `docs/ROADMAP.md`, and this file's terminology/decision criteria, then summarize the
  responsibility boundary.
- Judge from repository files and current source, not memory or prior conversation.
- Decide which layer owns the change before editing.
- Reflect layer-boundary changes only in durable sources: README, AGENTS, ADR, or ROADMAP.
- Access control means `public` for host surface, `package` for real cross-target owner
  interfaces, and omitted access for target-internal defaults. Do not open a whole owner
  helper through `package extension`.
- Prefer existing local patterns and helper APIs.
- Keep source/test filenames responsibility-revealing.
- Do not revert user changes.
- Prefer `rg` or `rg --files` for file search.
- Use `apply_patch` for manual file edits.

## Testing Principles

- Tests should reflect source layers and responsibilities.
- Test description metadata should be written in Korean.
- Test bodies should use `// Given`, `// When`, and `// Then`.
- The behavior exercised in `When` should belong to the layer that test file is
  responsible for.
- Behavior owned by another layer should be used as `Given` setup data or split into a
  separate test.
- Prefer basic unit behavior tests before fuzz or broad smoke tests.
- Keep test method names short; write detailed descriptions in Korean in `@Test("테스트 내용...")`
  metadata.

## Verification

Default verification after code changes:

```sh
swift test --quiet
swift build --product SlopadAppKitUI --quiet
swift build --product SlopadDebugApp --quiet
swift build --product SlopadUIBenchmarkApp --quiet
git diff --check
```

If package or target graph changes, also run `swift package dump-package`.
