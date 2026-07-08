# Loop Request Template

Use this template when asking for a bounded Slopad work loop. The goal is to make the
task type, completion criteria, owner boundary, and verification surface explicit before
editing starts.

```md
## Loop Type

Choose one:
- Structure change
- Bug fix
- Performance change
- AppKit adapter surface cleanup
- Documentation/glossary alignment

## Focus

- Area:
- Files, targets, or symbols to inspect first:
- What should stay out of scope:

## Problem Or Risk

- Current symptom, friction, or cleanup pressure:
- Suspected owner:
- Known constraints:

## Completion Criteria

Write at least three observable criteria.

- [ ] Behavior, boundary, or document state that must be true:
- [ ] Test, build, benchmark, or audit that must pass:
- [ ] Scope or non-goal that must remain unchanged:

## Evidence To Gather First

- Producer:
- Consumer:
- Fields or facts carried across the boundary:
- Existing tests, docs, benchmarks, or call sites to verify:

## Loop To Run

For structure changes:
`owner decision -> type inventory -> deletion/merge/access-shrink experiment -> deletion test -> place surviving types by owner/read intent -> verification -> durable doc update`

For bug fixes:
`symptom -> canonical owner -> why tests missed it -> focused test -> fix -> full verification`

For performance changes:
`hot-path hypothesis -> 100/1000/10000 benchmark -> counter check -> CSV/doc update -> regression risk record`

## Verification

- Focused check:
- Full check:
- Documentation update needed:
- Benchmark or CSV update needed:
```

Short example:

```md
## Loop Type

Structure change

## Focus

- Area: `SlopadBlockLayout/TextLayout`
- Files, targets, or symbols to inspect first: `TextLayoutCache`, `BlockMeasureRequest`
- What should stay out of scope: AppKit drawing behavior

## Problem Or Risk

- Current symptom, friction, or cleanup pressure: text measurement helpers may be placed
  by folder name instead of producer/consumer ownership.
- Suspected owner: `SlopadBlockLayout`
- Known constraints: keep `BlockTextLayoutProtocol` in `SlopadCoreModel`.

## Completion Criteria

- [ ] Surviving types are placed by owner/read intent, not folder symmetry.
- [ ] A deletion, merge, or access-shrink attempt is checked before keeping a helper.
- [ ] `swift test --quiet` and `git diff --check` pass.
```
