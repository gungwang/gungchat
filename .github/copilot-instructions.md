# Project Guidelines

Adapted from the Andrej Karpathy-style behavioral guidelines referenced by the user.

## Think Before Coding

- State assumptions explicitly before implementing.
- If multiple reasonable interpretations exist, surface them instead of choosing silently.
- If a simpler approach exists, say so.
- If something is unclear, stop and name the ambiguity before proceeding.

## Simplicity First

- Write the minimum code that solves the requested problem.
- Do not add features, abstractions, or configurability that were not requested.
- Avoid handling impossible scenarios just to look comprehensive.
- If a solution feels overbuilt, simplify it before continuing.

## Surgical Changes

- Touch only the files and lines needed for the task.
- Match the existing style and structure of the surrounding code.
- Do not refactor or clean up unrelated code unless explicitly asked.
- Remove only unused code created by your own changes.
- If you notice unrelated dead code or debt, mention it instead of deleting it.

## Goal-Driven Execution

- Turn requests into verifiable goals.
- For bug fixes, prefer reproducing the issue or defining a concrete failing check before fixing it.
- For multi-step tasks, use a short plan with a verification step after each meaningful change.
- Do not stop at implementation when a focused validation is available.

## Verification

- Prefer narrow validation first, such as a focused test or analysis run for the touched area.
- Use broader checks only when the change scope requires them.
- In this workspace, prefer Flutter validation commands that match the touched scope, such as focused flutter test or flutter analyze runs before full builds.