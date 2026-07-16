# ROADMAP

This document keeps only the current development direction for the Slopad project.

## Achieved Baseline

- The headless `EditorSession` facade is the host-facing surface.
- The SwiftPM target split is complete. `SlopadEngine` composes `SlopadEditorModel` and
  `SlopadBlockLayout`; those two targets do not import each other.
- `SlopadCoreModel` contains only public vocabulary, backend seams, and package canonical
  document values.
- `SlopadAppKitTextKit` provides the AppKit/TextKit2-based measurement, line fragment,
  caret/selection rect, hit-test, and drawing backend.
- The default `BlockHeightIndexStorage` implementation is RBTree-backed. Array storage is
  not the default for structural-mutation-heavy paths.
- The viewport-driven lazy initial layout baseline is in place. Large documents exact-
  measure blocks around the viewport and start the rest from cached/estimated heights.
- The `SlopadAppKitUI` package provides the first reusable AppKit view/controller/input/
  render adapter surface for downstream macOS apps. It also handles edge autoscroll near
  the top/bottom of the viewport during block selection rectangles, gutter block
  selection, and block reorder.
- AppKit block appearance customization is a chrome-only public contract. Host renderers
  can draw backgrounds, borders, gutters, and markers, while the adapter always owns
  TextKit2 fragment-based text drawing plus text-selection, caret, and live marked-content
  feedback after clipped and isolated host chrome passes.
- Public AppKit `resetDocument` and `scrollDocument` actions are synchronized boundaries.
  Reset updates the replacement document and native surface before returning; scroll
  updates viewport, visible snapshot, canvas, and observers without discarding live
  marked text or stealing focus. Unsynchronized batching helpers remain package-only.
- `Fixtures/DownstreamAppKitHost` compile-checks the intended downstream API using regular
  public imports only.
- The AppKit path already routes native command selectors, IME/marked text, plain-text
  copy/cut/paste, undo/redo, scroll reveal, text selection, block selection, block
  selection rectangles, and selected-block drag/reorder through `EditorSession`.
- The editing model already supports block split/merge, indent/outdent, block movement,
  block kind changes, todo toggling, snapshot-based undo/redo with a bounded budget, and
  markdown prefix shortcuts for common block kinds.
- The inline content model already stores bold, italic, code, and link marks, and the
  TextKit backend consumes inline runs for measurement and rendering.
- The AppKit UI benchmark harness covers scroll, native insert, composition, height
  expansion, block selection, block reorder, mixed interaction, subtree delete, and
  subtree reorder at 100/1000/10000 block scales.

## Current Product Gaps

These are not a request to rebuild existing behavior. They are the missing contracts
needed before a host app can use the engine as a Notion/Craft-style editor surface.

- AppKit adapter extension points are not yet explicit enough for product hosts. Key
  command maps, pasteboard policy, IME/composition policy, scroll reveal behavior, pointer
  drag behavior, and remaining adapter policies need stable public contracts.
- Clipboard support is currently plain text. Structured block copy/paste, rich inline
  paste, and format negotiation with platform pasteboards are not yet modeled.
- Inline marks exist in the canonical model and TextKit rendering path, but there is no
  public `EditorInputEvent` command surface for toolbar/menu shortcuts such as bold,
  italic, code, link edit, or clear formatting.
- Block kind transforms exist inside `EditorModel`, and markdown prefix shortcuts exercise
  them, but product commands such as slash menu block transform, toolbar transform, and
  todo checkbox toggling still need host-facing input events.
- The document is tree-capable, but collapsed subtree state, visible-order filtering,
  selection behavior, reveal behavior, and copy/paste behavior for collapsed content are
  not implemented.
- Markdown import/export is still a product feature, not the same thing as markdown
  prefix shortcuts.

## Next Direction

Priority order:

- P0 - AppKit integration contract hardening
  - Stabilize the reusable AppKit host surface before adding large product features.
  - Define extension points for key command mapping, pasteboard read/write policy,
    IME/marked-text lifecycle, scroll reveal, and pointer drag selection/reorder. Preserve
    the chrome-only renderer boundary while these policies are added.
  - Keep platform code limited to native callbacks, drawing, focus, scroll, and adapter
    policy. Semantic editing behavior stays behind `EditorSession`.
  - Contract regression gate: the downstream fixture continues to build without
    `@testable`, package-only controller state, raw callbacks, or development hooks.
  - Completion signal: downstream hosts can customize the adapter without reaching into
    `EditorModel`, `BlockLayout`, layout cache, or canonical `Document`.

- P1 - Block interaction UX contract
  - Turn the existing block selection, selection rectangle, drag/reorder, Enter, Escape,
    Delete, cut, copy, paste, and select-all behavior into an explicit product contract.
  - Define structured block copy/paste semantics separately from existing plain-text
    clipboard behavior.
  - Preserve the current model that multi-block work is block selection, not cross-block
    text ranges.
  - Completion signal: each user-visible block selection transition has a Session test and
    a real AppKit verification path.

- P2 - Product command surface for block transforms and inline formatting
  - Add host-facing input events for block kind transform, todo toggling, inline mark
    toggle/application, link editing, code styling, and clear formatting.
  - Reuse the existing canonical `BlockKind`, `BlockContent.InlineMark`, and `EditorModel`
    command owners instead of exposing `EditorModel` directly.
  - Completion signal: toolbar/menu/slash-command style hosts can express product editing
    commands only through `EditorSession` input values.

- P3 - Structured paste and Markdown import/export
  - Keep markdown as import/export format and input shortcut syntax, not canonical state.
  - Add structured block paste before broad markdown import/export if product editing
    needs copy/paste workflows first.
  - Preserve inline marks and block tree structure when the pasted/imported format can
    carry them; fall back to plain text when it cannot.
  - Completion signal: paste/import behavior round-trips through canonical `Document` and
    has focused engine tests plus AppKit pasteboard coverage.

- P4 - Collapsed subtree feature
  - Add collapsed state without making collapsed visibility canonical document content
    unless the owner decision proves it should be stored there.
  - Update visible-order, selection, reveal, hit-test, render, copy/paste, drag/drop, and
    benchmark scenarios for collapsed content.
  - Completion signal: collapsed subtrees change visible layout and interaction behavior
    without corrupting canonical tree structure or block selection semantics.

- P5 - Performance gates for product UX
  - Extend the existing 100/1000/10000 AppKit and session benchmark coverage as new UX
    paths land.
  - Define thresholds for ordinary typing, composition, text selection, block selection,
    structured paste, collapsed subtree reveal, and subtree reorder.
  - Keep ordinary typing bounded around changed blocks and structural editing bounded by
    ordered diff range where possible.
  - Re-check blockID-based measurement invalidation cost in large caches and design a
    secondary cache-key index only if measured data shows it is needed.
  - Explore coalescing or delta strategies to reduce snapshot undo/redo memory cost.

- P6 - Platform expansion
  - Design a UIKit adapter only after the AppKit adapter contract is stable enough to be a
    reusable reference.
  - Preserve the `BlockTextLayoutProtocol` seam when adding text layout backends beyond
    TextKit2.

## Open Risks

- TextKit2 geometry is sensitive to OS/font/layout-manager behavior, so unit tests should
  focus on invariants.
- If the AppKit UI package accumulates too many convenience features, platform adapter
  code can start owning engine semantics again. The AppKit package should stay focused on
  callback translation, drawing, and focus/scroll sync.
- If public product commands are added by exposing internal `EditorModel` or `BlockLayout`
  types, the host-facing Session boundary will regress.
- Structured paste can easily become a second canonical model. Paste/import should always
  normalize into the tree-capable `Document`/`Block` store.
- Collapsed subtree state needs an owner decision before implementation. Treating it as
  both canonical document content and runtime visibility policy would create conflicting
  sources of truth.
- Full-rebuild layout remains the correctness baseline, but large documents need both
  incremental layout and viewport-driven lazy measurement paths.
- Snapshot undo/redo is simple and correct, but memory cost can become high for large
  documents.
- Markdown prefix shortcuts are implemented, but broad markdown import/export and rich
  paste are still separate product features.
