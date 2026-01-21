<!--
SPDX-FileCopyrightText: Copyright 2025 Arm Limited and affiliates.

SPDX-License-Identifier: Apache-2.0
-->

# CONTRIBUTING

Thank you for your interest in contributing to ML Tool Solutions.
This document describes the recommended development workflow, coding standards, and how to use the repository's automated tooling, particularly the pre-commit hooks that enforce SPDX/REUSE compliance, formatting checks, and other quality gates.

We welcome contributions through GitHub Pull Requests.
Please read this guide before submitting changes.

## Development Workflow

### Fork, Branch, and Submit a PR

1. Fork the repository.
2. Create a feature branch:

    ```bash
    git checkout -b my-feature
    ```

3. Make changes.
4. Ensure all automated checks (pre-commit hooks) pass locally.
5. Submit a pull request on GitHub.

All PRs must have:

- A clear description of the change.
- Passing CI checks.
- SPDX/REUSE-compliant licensing metadata (handled automatically by the hooks).
- Clean commits or a tidy commit history.

## Pre-Commit Hooks (IMPORTANT)

This repository uses `pre-commit` to automatically enforce:

- SPDX/REUSE-compliant license and copyright notices
- Correct SPDX headers and/or sidecar `.license` files
- `reuse-lint` checks on modified files
- Trailing whitespace cleanup

These hooks ensure all contributions meet licensing and formatting requirements before changes are committed.

### Install `pre-commit`

You only need to do this once per machine:

```bash
pip install pre-commit
pre-commit install
```

This installs the git hooks so they run automatically before each commit.

Verify installation:

```bash
pre-commit --version
```

### Typical Contributor Workflow with Hooks

1. Modify files.
2. Stage your changes:

    ```bash
    git add .
    ```

3. Commit:

    ```bash
    git commit -m "..."
    ```

4. The hooks run automatically. If they fail:
   - Inspect the changed files (`git diff`)
   - Apply fixes
   - Stage again
   - Re-run:

        ```bash
        pre-commit run --all-files
        ```

5. Push once everything passes:

    ```bash
    git push
    ```

## Licensing Requirements (SPDX/REUSE)

This project follows the [REUSE specification](https://reuse.software).

Every file must contain:

- An SPDX license identifier
- `SPDX-FileCopyrightText` statements

For formats where inline headers are not appropriate (e.g., binaries, JSON), use sidecar .license files.
The pre-commit hooks manage most of this automatically.

## Coding Conventions

- Keep scripts POSIX-compatible unless necessary.
- Use SPDX headers based on examples already in the repository.

## Contact Us

If you have questions, comments, and/or suggestions? Please raise an [issue](https://github.com/ARM-software/Tool-Solutions/issues/new/choose).
