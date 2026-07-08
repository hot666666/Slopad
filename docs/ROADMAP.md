# ROADMAP

This document keeps only the current development direction for the Slopad project.

## Achieved Baseline

- The headless `EditorSession` facade is the host-facing surface.
- The SwiftPM target split is complete. `SlopadEngine` composes `SlopadEditorModel` and
  `SlopadBlockLayout`; those two targets do not import each other.
- `SlopadCoreModel` contains only public vocabulary, backend seams, and package canonical
  document values.
- `SlopadTextKit` provides the TextKit2-based measurement, line fragment,
  caret/selection rect, hit-test, and drawing backend.
- The default `BlockHeightIndexStorage` implementation is RBTree-backed. Array storage is
  not the default for structural-mutation-heavy paths.
- The viewport-driven lazy initial layout baseline is in place. Large documents exact-
  measure blocks around the viewport and start the rest from cached/estimated heights.
- The `SlopadAppKitUI` package provides the first reusable AppKit view/controller/input/
  render adapter surface for downstream macOS apps. It also handles edge autoscroll near
  the top/bottom of the viewport during block selection rectangles, gutter block
  selection, and block reorder.

## Next Direction

- `SlopadAppKitUI` hardening
  - Narrow the block-kind renderer customization surface to real app needs.
  - Clarify host extension points for key command maps, pasteboard, IME composition,
    pointer drag selection, and scroll reveal.

- Editing product features
  - Markdown import/export.
  - Collapsed subtrees.
  - Richer inline marks: italic, code, and links.
  - More block types and clearer block chrome measurement policy.

- Performance and correctness
  - Check blockID-based measurement invalidation cost in large caches, and design a
    secondary cache-key index if needed.
  - Define regression thresholds: ordinary typing should measure around changed blocks,
    while structural editing should stay bounded by the ordered diff range. Verify with
    CSV diffs.
  - Explore coalescing or delta strategies to reduce snapshot undo/redo memory cost.

- Platform expansion
  - Once the AppKit adapter sufficiently separates engine-owned semantics from
    platform-owned drawing/input responsibility, design a UIKit adapter on the same
    `EditorSession` surface.
  - Preserve the `BlockTextLayoutProtocol` seam when adding text layout backends beyond
    TextKit2.

## Open Risks

- TextKit2 geometry is sensitive to OS/font/layout-manager behavior, so unit tests should
  focus on invariants.
- If the AppKit UI package accumulates too many convenience features, platform adapter
  code can start owning engine semantics again. The AppKit package should stay focused on
  callback translation, drawing, and focus/scroll sync.
- Full-rebuild layout remains the correctness baseline, but large documents need both
  incremental layout and viewport-driven lazy measurement paths.
- Snapshot undo/redo is simple and correct, but memory cost can become high for large
  documents.
- Inline markdown shortcuts are not part of the current EditorModel baseline scope.
