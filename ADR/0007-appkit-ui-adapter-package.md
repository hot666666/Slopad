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
- block-kind chrome customization through a renderer interface

It depends on `SlopadEngine` and `SlopadTextKit`. It does not expose `EditorModel`,
`BlockLayout`, canonical `Document`, layout cache, or height-index storage.

## Consequences

- macOS apps can depend on `SlopadAppKitUI` for a working AppKit editor surface.
- Debug-only scenario/HUD state stays in `SlopadDebugApp`.
- Benchmark-only frame loops, CSV output, and forced display flushes stay in
  `SlopadUIBenchmarkApp`.
- AppKit UI customization happens through adapter-level renderer and controller hooks,
  not by moving editor semantics out of `EditorSession`.
- A future UIKit adapter should follow the same rule: platform package owns native
  callback/drawing/focus glue while the engine owns semantic editing behavior.
