# 0007 - Provide AppKit UI as a Reusable Adapter Package

Date: 2026-07-08

## Status

Accepted

## Context

The debug host proved the AppKit/TextKit2 path, but host code also carries debug HUD
state, local verification helpers, and benchmark-only runners. Downstream macOS apps
need a package they can embed without copying debug or benchmark-only behavior.

The engine still must remain headless: AppKit code should translate native callbacks,
draw session output, and synchronize focus/scroll state, not own canonical document or
selection semantics.

## Decision

Add `SlopadAppKitUI` as a library product and SwiftPM target.

The package owns reusable AppKit adapter code:

- `NSView` + `NSTextInputClient` callback bridging
- key command selector mapping
- mouse/pointer interaction dispatch into `EditorSession`
- active text input and IME/marked-text synchronization
- scroll/focus synchronization
- TextKit-backed canvas drawing
- block-kind chrome customization through `AppKitBlockChromeRenderer`

The block appearance extension point is chrome-only. A host renderer receives block
identity, kind, marker, depth, frame, style, graphics context, and active/selected state.
Its initializer is internal because only the adapter can assemble a valid context. It does
not receive the Session snapshot, concrete text layouter/renderer, text render descriptor,
or dirty rectangle. `SlopadAppKitUI` clips the hook to its block frame, saves and restores
graphics state, then performs all chrome passes before its TextKit2 fragment-based text
drawing, text selection, and caret feedback. Live marked text is projected into the
effective content used by that same adapter-owned text drawing path.

Replacing the complete native text pipeline requires a host to build a custom platform
adapter around `EditorSession` and use a coherent backend that keeps layout, drawing, hit
testing, caret/selection geometry, and native text geometry consistent. It is not exposed
as another high-level paint hook in `SlopadAppKitUI`.

It depends on `SlopadEngine` and `SlopadAppKitTextKit`. It does not expose `EditorModel`,
`BlockLayout`, canonical `Document`, layout cache, or height-index storage.

## Consequences

- macOS apps can depend on `SlopadAppKitUI` for a working AppKit editor surface.
- Debug-only scenario/HUD state stays in `SlopadDebugApp`.
- Benchmark-only frame loops, CSV output, and forced display flushes stay in
  `SlopadUIBenchmarkApp`.
- AppKit UI customization happens through adapter-level renderer and controller hooks,
  not by moving editor semantics out of `EditorSession`.
- `AppKitBlockRenderer`, `AppKitBlockRenderContext`, and `drawBlock(_:)` are replaced by
  the chrome-specific names. This is intentionally source breaking: retaining the old
  whole-block hook would keep a path that can suppress native text/input feedback or draw
  it twice. Hosts migrate only their background, border, gutter, and marker drawing to
  `drawChrome(_:)`.
- A future UIKit adapter should follow the same rule: platform package owns native
  callback/drawing/focus glue while the engine owns semantic editing behavior.
