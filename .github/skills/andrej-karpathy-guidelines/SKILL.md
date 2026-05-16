---
name: andrej-karpathy-guidelines
description: 'Apply Andrej Karpathy-style coding guidance. Use for planning, debugging, implementing, or reviewing changes with explicit assumptions, simplicity-first decisions, surgical edits, and goal-driven validation.'
argument-hint: 'Task, bug, or change request to apply the guidelines to'
user-invocable: true
disable-model-invocation: true
---

# Andrej Karpathy Guidelines

## When to Use

- The user wants a Karpathy-style approach to implementation or review.
- A task is ambiguous and assumptions should be made explicit before coding.
- A change risks becoming overcomplicated or too broad.
- You want a deliberate workflow that ties each step to a focused validation.

## Procedure

1. Restate the task as a concrete, testable goal.
2. State the key assumptions and ambiguities explicitly.
3. Choose the simplest solution that satisfies the request.
4. Limit edits to the smallest relevant surface.
5. Run the narrowest available validation for the changed slice.
6. If validation fails, repair locally before expanding scope.

## Core Rules

### Think Before Coding

- Do not assume silently.
- Surface tradeoffs when there is more than one reasonable path.
- Ask for clarification when the ambiguity changes the implementation.

### Simplicity First

- No speculative abstractions.
- No extra features beyond the request.
- No configurability that is not needed yet.

### Surgical Changes

- Do not refactor adjacent code unless the task requires it.
- Match the local code style.
- Remove only the dead code your own change creates.

### Goal-Driven Validation

- Prefer focused tests or repro steps.
- Use broader checks only when necessary.
- Finish with explicit evidence that the goal was verified.

## Success Signals

- The diff is narrowly aligned with the request.
- Validation directly covers the changed behavior.
- Assumptions were surfaced before implementation rather than after failure.