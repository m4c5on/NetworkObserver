---
status: Accepted
owner: "Architect"
reviewers: []
updated_at: "2026-09-05"
feature_size: "N/A — foundational (repo-level)"
ticket: "N/A"
---

# 0002 — Organize every feature screen with the project's MVI pattern

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Architect + Maksym (survey greenfield session)

## Context

The repo already carries a project-authored architecture guide at
`.claude/skills/ios-MVI-architecture/SKILL.md`, describing a strict Model→View→Intent pattern
(namespace `Domain` enum, pure `Reducer`, `@Observable` `Store`, dumb `View`) with an explicit
checklist "every new feature screen must follow this pattern exactly." This decision formally adopts
that pre-existing guide as the project's architectural style rather than picking a competing one
during survey.

## Decision drivers

- A concrete, detailed convention already exists in-repo and was authored deliberately (not
  discovered by scanning code, since no feature code exists yet).
- Unit-testability without mocking is called out as a goal of the pattern (pure `Reducer`), matching
  the project's `ios-tdd-workflow` skill which mandates red-green-refactor for new business logic.
- A single-feature v1 (connection-health) doesn't strain the pattern's ceremony, and consistency
  matters more than saving boilerplate for a codebase meant to grow feature-by-feature.

## Considered options

1. **MVI per the existing `.claude/skills/ios-MVI-architecture` guide** — namespace `Domain` enum +
   `Reducer` + `Store` + `View`, as already documented.
2. **Plain MVVM** — `ObservableObject`/`@Observable` view models with imperative methods, no
   Intent/Effect vocabulary; more familiar/less ceremony.
3. **The Composable Architecture (TCA) or a similar third-party library** — an off-the-shelf
   Redux-style framework, adds a dependency.

## Decision outcome

**Chosen:** Option 1. The pattern is already specified in detail and referenced by the project's own
tooling (`ios-tdd-workflow`, `ios-swift-expert` skills assume it), so adopting it avoids maintaining
two competing conventions and lets `scaffold`/`implement` follow an existing, unambiguous contract
instead of inventing one.

## Consequences

**Positive**
- No ambiguity for the first feature (`connection-health`) — the pattern, file layout, and testing
  approach are already written down.
- Reducers are pure and unit-testable with zero mocking, aligning with the TDD workflow already
  configured for this repo.

**Negative**
- More files/boilerplate per feature (`Domain`, `Reducer`, `Store`, `View`) than a plain MVVM
  view-model would need for a single simple screen.

**Neutral**
- If a future screen turns out too simple to justify the full namespace (e.g. a static settings
  screen), that call is made per-feature during `design`/`implement`, not here.

## Links

- Existing convention: `.claude/skills/ios-MVI-architecture/SKILL.md`
- Architecture map: [[../architecture-map.md]]
- Related ADR: [[0001-swift-swiftui-menubarextra-stack]]
