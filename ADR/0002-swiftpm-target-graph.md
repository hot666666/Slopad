# 0002 - Keep the SwiftPM Target Graph as the Architecture Boundary

Date: 2026-07-08

## Status

Accepted

## Context

The source tree used to carry broad internal coupling because editor semantics, layout
projection, public vocabulary, data structures, TextKit implementation, and demo code
were not enforced by the compiler as separate modules.

The intended dependency graph is:

```text
SlopadEditorModel ─────────────> SlopadCoreModel
SlopadBlockLayout ─────────────> SlopadCoreModel + SlopadDataStructure
SlopadEngine / EditorSession ──> SlopadCoreModel + SlopadEditorModel + SlopadBlockLayout
SlopadAppKitTextKit ───────────> SlopadCoreModel
SlopadAppKitUI ────────────────> SlopadEngine + SlopadAppKitTextKit
```

## Decision

Keep the SwiftPM targets aligned to ownership:

- `SlopadCoreModel`: public vocabulary, backend seam values, package canonical document
  values.
- `SlopadEditorModel`: semantic document/selection/command/history owner.
- `SlopadBlockLayout`: layout projection, visible order, invalidation, geometry, text
  measurement cache, height index owner.
- `SlopadDataStructure`: pure data structures with no editor vocabulary.
- `SlopadEngine`: public `EditorSession` facade and orchestration.
- `SlopadAppKitTextKit`: AppKit/TextKit2 text layout/rendering backend.
- `SlopadAppKitUI`: reusable AppKit view/controller adapter.
- `SlopadDebugApp`: AppKit reference/debug host.
- `SlopadUIBenchmarkApp`: AppKit UI benchmark harness.

Use Swift `package` access for cross-target internal interfaces. Use `public` only for
host-facing session contracts, public vocabulary, and backend seam values.

## Consequences

- `SlopadEditorModel` must not import `SlopadBlockLayout`.
- `SlopadBlockLayout` must not import `SlopadEditorModel`.
- `SlopadEngine` may compose both owners and translate between semantic change facts and
  layout invalidation facts.
- `SlopadAppKitTextKit` implements the CoreModel backend seam and must not depend on
  `SlopadEngine`; adapting Session render descriptors to TextKit calls belongs to
  `SlopadAppKitUI`.
- `SlopadCoreModel` is not a shared helper bucket. A value belongs there only when it is
  public vocabulary, a backend seam value, or package canonical document state.
- Any new public/package surface needs producer, consumer, invariant, and dependency
  direction evidence.
