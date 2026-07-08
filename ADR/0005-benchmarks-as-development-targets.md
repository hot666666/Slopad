# 0005 - Keep Benchmarks as Development Targets, Not Public Products

Date: 2026-07-08

## Status

Accepted

## Context

Slopad needs benchmark executables for layout/index/storage work. These executables use
release builds, instrumentation flags, local CSV output, and sometimes package-internal
SPI. They are part of the development and regression workflow, not the library surface
that downstream users should depend on.

At the same time, keeping benchmarks inside the package is useful because benchmark code
can exercise package access without widening regular public API.

## Decision

Keep `SlopadHeightBenchmark` and `SlopadSessionBenchmark` as executable targets under
`Benchmarks/`, but do not list them as SwiftPM products.

The public package products are the engine/runtime library, the TextKit backend library,
and the AppKit demo executable.

## Consequences

- Build benchmark executables by target:

  ```sh
  swift build --target SlopadHeightBenchmark --quiet
  swift build --target SlopadSessionBenchmark --quiet
  ```

- Run benchmark executables by name when needed:

  ```sh
  swift run -c release -Xswiftc -DSLOPAD_BENCHMARK_INSTRUMENTATION SlopadSessionBenchmark
  ```

- Do not add benchmark-only types to public API to make benchmark code easier to write.
- Treat benchmark baselines and docs as development evidence, not consumer-facing product
  surface.
