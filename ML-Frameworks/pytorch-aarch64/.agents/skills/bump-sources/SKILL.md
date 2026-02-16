---
# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

name: bump-sources
description: Use only when explicitly asked to bump pinned sources in pytorch-aarch64/versions.sh and handle follow-on patch issues in pytorch-aarch64/get-source.sh. Canonical procedure is in this directory's README.
---

## Goal

Update `versions.sh` to the newest allowed upstream commits/tags/wheels while keeping every commit reproducible and leaving clear provenance comments where required.

## Canonical instructions

Follow the documentation section:

- `./README.md` → **"Updating pinned versions"**

Treat that README section as the source of truth. If this skill conflicts with the README, prefer the README.

## Hard requirements (do not deviate)

### Scope

- Only operate within this directory (i.e. `pytorch-aarch64/`).
- Only update `./versions.sh` (and `./get-source.sh` if required by patch status).
- Preserve existing variable names and formatting.

### Pin selection rules

- Use the upstream branches/tags/wheels described in the README section.
- Do not guess values if network access prevents verification.

### Provenance comments

- Commit pins: include provenance per README (branch/source + date; and version where required).
- Tag pins: trailing comment is **date only** (YYYY-MM-DD preferred).
- `TORCHVISION_NIGHTLY`: **no trailing comment**.

### Python ABI

- Determine Python ABI from repo config (prefer `./build-wheel.sh`; fallback to the existing `TORCHVISION_NIGHTLY` pattern).
- Do not guess the ABI.

### Patch handling (`./get-source.sh`)

- Run `./get-source.sh` after updating `./versions.sh`.
- If output shows **"No changes -- Patch already applied."**, remove the corresponding patch line from `./get-source.sh`.
- If patch fails and is merged upstream, remove that patch line from `./get-source.sh`.
- If patch conflicts and is not merged, report which patch failed and advise: "ask PR owner to rebase onto tip".
- If `./get-source.sh` was edited, rerun `./get-source.sh` once to verify clean application.

## Output expectations

Provide:

- A short summary of what changed (hashes/tags/wheels).
- The edits made to `./versions.sh` (and `./get-source.sh` if changed).
- Commands run and key results/errors.