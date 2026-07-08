<p align="center">
  <img src="Resources/Icon.png" alt="Slopad icon" width="300" height="300">
</p>

<h1 align="center">Slopad</h1>

<p align="center">
  WIP Swift block editor app, currently focused on its reusable editor engine.
</p>

<p align="center">
  <img alt="Status: WIP" src="https://img.shields.io/badge/status-WIP-f59e0b">
  <img alt="Swift 6.0" src="https://img.shields.io/badge/Swift-6.0-f05138">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-111827">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-2563eb">
</p>

Slopad is a work-in-progress Swift app project for a block editor. The app layer is
still early; most of the current codebase is the reusable editor foundation that the app
will use.

That foundation is `SlopadEngine`: a headless block editor engine for
Notion/Craft-style editors where the document is a tree of blocks, the engine owns editing
semantics, and platform code supplies native input, drawing, and text layout.

The engine is designed to stay platform-independent. An embedding app supplies two edge
pieces: a native UI layer that translates platform callbacks into engine inputs, and a
text layout backend that satisfies `BlockTextLayoutProtocol`.

The current project proves that path on macOS with AppKit UI and a TextKit2 text layout
backend. `SlopadAppKitUI` is the reusable AppKit adapter around the engine; it is not the
engine model itself.

## Demo

<img src="Resources/demo.gif" alt="Slopad debug demo" width="720">

```sh
swift run SlopadDebugApp
```

## Current Focus

SlopadEngine owns the semantic editor model:

- block document state and block identity
- caret, text selection, and block selection
- keyboard, pointer, native command, and IME/composition semantics
- command application, undo/redo, and semantic change projection
- block layout orchestration, hit testing, reveal geometry, and render snapshots

The engine does not own platform widgets. A host view receives native callbacks,
translates them into engine input values, asks the engine for layout/render/hit-test
facts, and draws using the platform backend it chose.

## Engine Architecture

```mermaid
flowchart TB
    AppKitUI["UI Framework\nSlopadAppKitUI"]
    Engine["SlopadEngine\nEditorSession facade"]
    Vocabulary["SlopadCoreModel\npublic vocabulary + package Document"]
    Model["SlopadEditorModel\nsemantic document / selection / commands"]
    Layout["SlopadBlockLayout\nvisible order / geometry / invalidation"]
    HeightIndex["BlockHeightIndexStorage\nblock y/height prefix sums"]
    Tree["SlopadDataStructure\nPrefixSumRedBlackTree"]
    TextLayout["TextLayout\nbackend seam + layout cache"]
    TextKit["Text Engine\nSlopadTextKit"]

    AppKitUI --> Engine
    AppKitUI --> TextKit
    Engine -.-> Vocabulary
    Engine --> Model
    Engine --> Layout
    Layout --> HeightIndex
    HeightIndex --> Tree
    Layout --> TextLayout
    TextKit -. implements .-> TextLayout
```

### Architecture Components

- `SlopadEngine`: host-facing `EditorSession` facade. It accepts input, composes semantic
  and layout owners, and returns render, hit-test, reveal, and redraw facts.
- `SlopadEditorModel`: canonical document, selection, command, transaction, history, and
  semantic change owner.
- `SlopadBlockLayout`: visible order, geometry, invalidation, text-layout cache, and
  block height index owner.
- `SlopadCoreModel`: shared contracts, canonical `Document`/`Block` values, and
  `BlockTextLayoutProtocol`.
- `SlopadDataStructure`: pure storage such as `PrefixSumRedBlackTree`, with no editor or
  platform vocabulary.
- UI & Text framework layer: outside the engine. The current path uses AppKit through
  `SlopadAppKitUI` and TextKit2 through `SlopadTextKit`.

`SlopadEditorModel` and `SlopadBlockLayout` do not import each other. `EditorSession`
combines their results and translates semantic changes into layout invalidation.

SwiftPM keeps these responsibilities in separate targets. See `Package.swift` for the
exact product and target list.

## Development Targets

The repository also keeps benchmark and debug targets for development convenience. They
validate the current AppKit/TextKit2 path and performance behavior, but they do not define
engine semantics.

Benchmark targets:

- `SlopadUIBenchmarkApp`: AppKit UI benchmark harness for frame loops, CSV output, and
  display flush checks.
- `SlopadHeightBenchmark`: block height/index benchmark executable under `Benchmarks/`.
- `SlopadSessionBenchmark`: engine/session benchmark executable under `Benchmarks/`.

Debug target:

- `SlopadDebugApp`: macOS reference/debug host for scenarios, screenshots, and state
  assertions.

## Documentation

- `AGENTS.md`: working conventions for agents.
- `ADR/`: accepted architecture decisions.
- `docs/LOOP_REQUEST_TEMPLATE.md`: copy-paste template for bounded loop requests.
- `docs/ROADMAP.md`: achieved milestones, current product direction, and open risks.
- `docs/LESSONS_LEARNED.md`: failure patterns from past cleanup/refactor work.

## Development Checks

```sh
swift package dump-package
swift test --quiet
swift build --product SlopadAppKitUI --quiet
swift build --product SlopadDebugApp --quiet
swift build --product SlopadUIBenchmarkApp --quiet
git diff --check
```
