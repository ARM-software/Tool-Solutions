<!--
SPDX-FileCopyrightText: Copyright 2019-2026 Arm Limited and affiliates.

SPDX-License-Identifier: Apache-2.0
-->

# PyTorch for AArch64

> [!WARNING]
> This contains software which is
> - built from unreleased, development branches
> - with experimental features in active development
> - minimally tested
> - DO NOT USE IN PRODUCTION
> - FOR EVALUATION ONLY
>
> Release versions of PyTorch are available from: https://pypi.org/project/torch/

## Getting started
This [component](https://github.com/ARM-software/Tool-Solutions/tree/main/ML-Frameworks/pytorch-aarch64) of [ARM-Software's](https://github.com/ARM-software) [Tool Solutions](https://github.com/ARM-software/Tool-Solutions) repository provides scripts to build a wheel and a Docker image containing [PyTorch](https://www.pytorch.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile), as well as a selection of [examples and benchmarks](./examples/README.md).

Use the `./build.sh` script to build the wheel, which will be placed in the `results/` directory.

To launch a container with this wheel installed along with examples and requirements, run
```
./dockerize.sh <wheel-name>
```

For more details on the significant changes with each increment, see the [changelog](./CHANGELOG.md).

### Hardware support
The built wheel is intended for Arm® Neoverse™ platforms and includes optimizations for Armv8 and beyond. They have support for hardware features such as SVE and bfloat16, where available.

Note that only AArch64 is supported, you can check this with:

```
> uname -m
aarch64
```

## Examples
See [examples README.md](./examples/README.md).

## Development
`pytorch-aarch64` is also intended as a starting point for development of
PyTorch on AArch64.
By default, the scripts build a very specific single version of PyTorch, but they
are separable by design.
Specifically, `./build.sh` does 3 things:
- `./get-source.sh`,
- `./build-wheel.sh`,
- build docker container with wheel installed (`./dockerize.sh` without the
  `docker run`).

To use this for development, do an initial run of `./get-source.sh` (or
all of `./build.sh`).
Then you can modify the sources, and rerun `./build-wheel.sh` (which builds
incrementally for faster iteration) to get a wheel with your changes in.
You can then test your changes by installing the wheel in a virtual environment
of your choice or use `./dockerize.sh <name-of-wheel>` to launch a container
with the wheel installed (along with examples).

Note: if the environment variable `GITHUB_TOKEN` is set then the build will
attemmpt to use `GITHUB_TOKEN` for authenticated access when downloading WIP patches.
This can avoid issues with rate-limiting on annonymous access.

Note: GitHub patches are cached in `utils/patch_cache` to save network
traffic. This also allows you to use local patches that are not yet upstream by
adding your patch to `utils/patch_cache` with the name
`<your commit hash>.patch`. Then use `github-apply-patch` as usual in
`get-source.sh`.

### Flags useful for development
- `--use-existing-sources` skips `get-source.sh` and just builds
- `--force` overwrites sources
- `--wheel-only` build just the torch wheel (no torchao or Docker image)

### Updating pinned versions

Pinned source hashes and component versions live in [`versions.sh`](./versions.sh).
When updating, follow the rules below so each commit of `pytorch-aarch64` remains a reproducible reference point.

> **Note:** In practice this process can be laborious.
> You may wish to use ChatGPT or Codex to help automate this process.
> For Codex, we provide a skill named `bump-sources`, located at `.agents/skills/bump-sources/SKILL.md`.

#### Commit hashes

For these dependencies, you should assign the commit hash from the latest commit to the appropriate variable in `versions.sh` (e.g. assign the latest commit hash for PyTorch to `PYTORCH_HASH`).

- PyTorch: https://github.com/pytorch/pytorch/tree/viable/strict
  - Use the latest commit on this branch. Build the wheel to determine the version used in the trailing comment.
  - Note: we use `viable/strict` because [all PyTorch tests are guaranteed to be passing on this branch](https://github.com/pytorch/pytorch/wiki/PyTorch-Workflow-Cheatsheet#developing-a-new-feature).

- ideep: https://github.com/intel/ideep/tree/ideep_pytorch
  - Use the latest commit on this branch.

- oneDNN: https://github.com/uxlfoundation/oneDNN/tree/main
  - Use the latest commit on this branch.

- TorchAO: https://github.com/pytorch/ao/tree/main
  - Use the latest commit on this branch.

- KleidiAI: https://github.com/ARM-software/kleidiai/tree/main
  - Use the latest commit on this branch. Use the project version from the `CMakeLists.txt` to set the version in the trailing comment.

#### Tags

For these dependencies, you should assign the latest tag from the releases to the appropriate variable in `versions.sh` (e.g. assign the latest tag for `ComputeLibrary` to `ACL_VERSION`).

- ComputeLibrary: https://github.com/ARM-software/ComputeLibrary/tags
  - Pick the newest release tag.

- OpenBLAS: https://github.com/OpenMathLib/OpenBLAS/tags
  - Pick the newest release tag.

#### Nightly wheels

For these dependencies, you should assign the latest nightly wheel version to the appropriate variable in `versions.sh` (e.g. assign the latest wheel version for `torchvision` to `TORCHVISION_NIGHTLY`).

- Torchvision: https://download.pytorch.org/whl/nightly/torchvision/
  - Pick the newest wheel matching: `+cpu`, the Python ABI (e.g. `cp312` for Python 3.12), `manylinux_2_28_aarch64.whl`.
    Record the dev version from the filename.
  - Example: `torchvision-0.26.0.dev20260215+cpu-cp312-cp312-manylinux_2_28_aarch64.whl` → `0.26.0.dev20260215`

#### After updating `versions.sh`

After bumping the sources, you will probably find that `./get-source.sh` will fail to apply the patches. There are a few possible causes:

- The PR has gone in; this means that you can delete the appropriate line in `./get-source.sh` because it is no longer needed.
- There is a conflict; you will need to ask the PR owner to rebase their patch onto the tip of the development branch.

You may also find that it no longer builds. There are no simple solutions to this, but you may want to try:

- Rolling some of the sources back to where they previously built successfully. First check if they build on their own, then whether they all build together.
- Build without the patches, then include them one by one.

## Motivation
PyTorch + ideep + oneDNN + ComputeLibrary is a deep stack. The purpose of
`pytorch-aarch64` is to let us see the future of that stack, so that we can:
- Test and demonstrate features in development which require changes in
  multiple places.
- Do integration testing, particularly to detect changes deep in the stack which
  unintentionally affect correctness/performance at the top.

In essence, `pytorch-aarch64` is a **canary**.
The priority is detecting problems early so that they can be fixed before any
part of the stack is released.
Therefore, **if you care about correctness, do not use this build**.
If you are interested in having a peek at the future, this is for you.

## Architecture
We try to keep all components of the stack which significantly affect
performance on AArch64 up to date.
That means we use commits off the following branches:
- PyTorch: viable/strict, which is the most recent main that passes the
  nightlies. We don't use main because there's no point us having to deal with
  already known issues.
- Ideep: ideep_pytorch, release pulled off this is the branch end up in PyTorch.
- oneDNN: main.
- ComputeLibrary: main.

Each commit of `pytorch-aarch64` is a fixed reference point, both for
benchmarking and bug fixes.
`./get-source.sh` achieves this by getting fixed hashes of of the components.
On top of this we apply patches from PRs, again fixed by commit.

Note that we get patches from PRs for two reasons:
- We can see the context of the patch: who did it, what was it for and most
  crucially whether it has been merged.
- We avoid the license ambiguity of patches from one project living in another

To keep up to date with the development branches of the components, there is a
helper script called `./bump-sources.sh`.
After bumping the sources, you will probably find that `./get-source.sh` will
fail to apply the patches. There are a few possible causes:
- The PR has gone in. This means you can delete the appropriate line in
  `./get-source.sh` because it is no longer needed.
- There is a conflict. You will need to ask the PR owner to rebase their patch
  onto the tip of the development branch.

You may also find that it no longer builds. There's no simple solutions to this,
but you may want to try:
- Roll some of the sources back to where they build. First check if they build
  on their own, then whether they all build together.
- Building without the patches, then include them one by one.

Testing is limited to running the examples.
If other failures are detected (e.g. PyTorch unit tests) they should be
reported (and fixed if you can!) but they do not have to block the bump.
It is more important that we continue to detect other problems as they arise
than `pytorch-aarch64` is 100% correct.
Needless to say: **if you care about correctness, do not use this build**.
