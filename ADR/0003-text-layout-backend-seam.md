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

`SlopadTextKit` is the current Apple TextKit2 adapter. It implements the seam and can be
used by AppKit hosts or the demo app, but TextKit2 types do not belong in
`SlopadEngine`, `SlopadEditorModel`, or `SlopadBlockLayout`.

## Consequences

- Do not rename `textLayouter` to `textMeasurer`; the seam covers more than height.
- A future UIKit or non-Apple backend should implement the same layout protocol instead
  of changing engine semantics.
- Layout cache invalidation belongs to `SlopadBlockLayout`, not the platform backend.
- Native views draw from session render descriptors and backend layout results; they do
  not own editor selection/composition semantics.
