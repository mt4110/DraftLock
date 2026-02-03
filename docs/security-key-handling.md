# DraftLock: API Key Handling Rules

## Non-negotiable rules

1. API key is stored in Keychain only.
2. Never display the stored key in UI (no "show" feature).
3. Never log/print the key.
4. Do not store key in:
   - Xcode Scheme env vars
   - UserDefaults
   - Local files / SQLite
   - Crash reports

## Allowed behavior

- Reading the key from Keychain for internal actions (e.g. connectivity test) is allowed.
- UI shows only: present/missing/error states.

## Why

- Prevent accidental leaks via git, screenshots, logs, schemes, or backups.
- Keep the secret surface area minimal and auditable.
