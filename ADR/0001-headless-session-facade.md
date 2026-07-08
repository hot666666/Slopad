# 0001 - Use a Headless Session Facade for Platform Hosts

Date: 2026-07-08

## Status

Accepted

## Context

Slopad is intended to be a native block editor engine, not an AppKit wrapper, `NSTextView`
subclass, or document-store-only library. Platform hosts need to send keyboard, pointer,
selection, IME/composition, reveal, hit-test, and render requests into the engine without
owning the editor semantics themselves.

The project also needs to remain portable to UIKit and other native stacks later. That
requires a stable engine interface whose inputs and outputs are simple values, while
platform-native views and event APIs stay outside the engine target.

## Decision

`EditorSession` is the public host-facing facade. It owns runtime orchestration and calls
two internal owners:

- `SlopadEditorModel` for canonical document state, selection, command application,
  transaction/history, and semantic changes.
- `SlopadBlockLayout` for visible order, block geometry, layout invalidation, reveal,
  hit-test geometry, and text-layout-backed measurement.

Native surface code, such as the AppKit demo view, receives OS callbacks and delegates
meaningful editor decisions to `EditorSession`.

## Consequences

- Host code should call `EditorSession` instead of constructing or exposing
  `EditorModel` or `BlockLayout`.
- `EditorSession` may translate semantic changes into layout invalidations, but it should
  not take ownership of canonical document mutation or block height/y storage.
- Demo/AppKit code can be a reference adapter, not the owner of editor state.
- A second platform implementation should add a new adapter around the same session
  facade, not fork the core semantics.
