# 0003 - Keep Text Layout Behind a Backend Seam

Date: 2026-07-08

## Status

Accepted

## Context

Block height is not a fixed property. It depends on text content, available width, style,
line fragments, inline marks, and platform text shaping behavior. Slopad currently proves
this path with TextKit2, but the engine is not supposed to be tied to AppKit/TextKit.

The text layout path must support more than height measurement: caret rects, selection
rects, text hit-testing, line fragment snapshots, and drawing handoff all depend on the
same block-local text layout facts.

## Decision

Keep the public text layout seam in `SlopadCoreModel/Layout` as
`BlockTextLayoutProtocol` and related value types. Keep block-local request construction
and cache policy inside `SlopadBlockLayout/TextLayout`.

`SlopadAppKitTextKit` is the current AppKit/TextKit2 backend. It implements the seam and
provides fragment layout, geometry, attributed-content, and drawing helpers to the
default `SlopadAppKitUI` adapter. TextKit2 types do not belong in `SlopadEngine`,
`SlopadEditorModel`, or `SlopadBlockLayout`.

The seam anchors a coherent geometry contract, not a height-only service or high-level
paint hook. `EditorSession` owns the live composition overlay and supplies it to
`BlockLayout`'s effective content projection. BlockLayout measurement, Session geometry
queries, and adapter drawing helpers then consume the same effective request. A complete
alternative pipeline therefore pairs a coherent backend with its own platform adapter
around `EditorSession`.

## Consequences

- Do not rename `textLayouter` to `textMeasurer`; the seam covers more than height.
- A future UIKit or non-Apple backend should implement the same layout protocol instead
  of changing engine semantics.
- Layout cache invalidation belongs to `SlopadBlockLayout`, not the platform backend.
- Adapting `EditorTextRenderDescriptor` to backend requests belongs to the platform UI
  adapter, so the TextKit backend does not depend on `SlopadEngine`.
- Native views draw from session render descriptors and backend layout results; they do
  not own editor selection/composition semantics.
- The default AppKit chrome/theme hook cannot replace backend text layout or drawing.
