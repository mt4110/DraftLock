# DraftLock: Pricing Snapshot Rules

## Invariants
- Pricing is fixed by JSON snapshot (version-controlled).
- Unit: per 1M tokens (input/output; cached_input optional).
- No silent updates: changing prices requires new snapshot + commit.

## Resolver rules (deterministic)
- Exact match on model id or alias.
- If not found, normalize by stripping "-YYYY-MM-DD" suffix and match again.

## Why
- Past ledger must remain reproducible.
- UI should never depend on "current web pricing".
