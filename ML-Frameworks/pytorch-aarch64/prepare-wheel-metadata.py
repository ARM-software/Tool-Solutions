# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

"""Reconcile wheel license metadata with dependencies pruned by get-source.sh."""

import argparse
import json
import re
import tomllib
from pathlib import Path


# Keep this allowlist aligned with the explicit removals in get-source.sh.
PRUNED_DEPENDENCIES = (
    "android/libs/fbjni",
    "third_party/NVTX",
    "third_party/aiter/3rdparty/composable_kernel",
    "third_party/composable_kernel",
    "third_party/cudnn_frontend",
    "third_party/cutlass",
    "third_party/fbgemm/external/composable_kernel",
    "third_party/fbgemm/external/cutlass",
    "third_party/fbgemm/fbgemm_gpu/experimental",
    "third_party/flash-attention",
    "third_party/llvm-openmp",
    "third_party/mslk",
)


def prepare_wheel_metadata(source_root: Path) -> int:
    pyproject = source_root / "pyproject.toml"
    original = pyproject.read_text(encoding="utf-8")
    metadata = tomllib.loads(original)
    licenses = metadata["project"]["license-files"]
    missing = [
        pattern
        for pattern in licenses
        if not any(path.is_file() for path in source_root.glob(pattern))
    ]
    unexpected = [
        pattern
        for pattern in missing
        if not any(
            pattern.startswith(dependency + "/")
            and not (source_root / dependency).exists()
            for dependency in PRUNED_DEPENDENCIES
        )
    ]
    if unexpected:
        raise ValueError("Missing licenses for retained dependencies: " + ", ".join(unexpected))
    if not missing:
        return 0

    # Replace only the project's multiline array, preserving other TOML and comments.
    section = re.search(r"(?ms)^\[project\][ \t]*(?:#[^\n]*)?\n.*?(?=^\[|\Z)", original)
    block = (
        re.search(r"(?ms)^license-files[ \t]*=[ \t]*\[.*?^\]", section.group())
        if section
        else None
    )
    if block is None:
        raise ValueError("Unsupported project.license-files layout; metadata was not changed")

    retained = [pattern for pattern in licenses if pattern not in missing]
    replacement = "license-files = [\n"
    replacement += "".join(f"    {json.dumps(pattern)},\n" for pattern in retained)
    replacement += "]"
    start, end = section.start() + block.start(), section.start() + block.end()
    updated = original[:start] + replacement + original[end:]
    metadata["project"]["license-files"] = retained
    if tomllib.loads(updated) != metadata:
        raise ValueError("Unexpected metadata change; pyproject.toml was not changed")
    pyproject.write_text(updated, encoding="utf-8")
    return len(missing)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_root", type=Path)
    args = parser.parse_args()
    try:
        removed = prepare_wheel_metadata(args.source_root)
    except (OSError, ValueError, KeyError) as error:
        parser.exit(1, f"error: {error}\n")
    print(f"Wheel metadata: removed {removed} missing license entries for pruned dependencies")


if __name__ == "__main__":
    main()
