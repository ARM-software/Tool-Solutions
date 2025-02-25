# TensorFlow for AArch64

> [!WARNING]
> This contains software which is
> - built from unreleased, development branches
> - with experimental features in active development
> - minimally tested
> - DO NOT USE IN PRODUCTION
> - FOR EVALUATION ONLY
>
> Release versions of TensorFlow are available from: https://pypi.org/project/tensorflow/

## Getting started
This [component](https://github.com/ARM-software/Tool-Solutions/tree/main/ML-Frameworks/tensorflow-aarch64) of [ARM-Software's](https://github.com/ARM-software) [Tool Solutions](https://github.com/ARM-software/Tool-Solutions) repository provides scripts to build a wheel and a Docker image containing [TensorFlow](https://www.tensorflow.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile), as well as a selection of [examples and benchmarks](./examples/README.md).

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
`tensorflow-aarch64` is also intended as a starting point for development of
TensorFlow on AArch64.
By default, the scripts build a very specific single version of TensorFlow, but they
are separable by design.
Specifically, `./build.sh` does 3 things:
- `./get-source.sh`,
- `./build-wheel.sh`,
- build docker container with wheel installed (`./dockerize.sh` without the
  `docker run`).

So, use this for development, do an initial run of `./get-source.sh` (or
all of `./build.sh`).
Then you can modify the sources, and rerun `./build-wheel.sh` (which builds
incrementally for faster iteration) to get a wheel with your changes in.
You can then test your changes by installing the wheel in a virtual environment
of your choice or use `./dockerize.sh <name-of-wheel>` to launch a container
with the wheel installed (along with examples).

## Motivation
TensorFlow + oneDNN + ComputeLibrary is a deep stack. The purpose of
`tensorflow-aarch64` is to let us see the future of that stack, so that we can:
- Test and demonstrate features in development which require changes in
  multiple places.
- Do integration testing, particularly to detect changes deep in the stack which
  unintentionally affect correctness/performance at the top.

In essence, `tensorflow-aarch64` is a **canary**.
The priority is detecting problems early so that they can be fixed before any
part of the stack is released.
Therefore, **if you care about correctness, do not use this build**.
If you are interested in having a peek at the future, this is for you.

## Architecture
We try to keep all components of the stack which significantly affect
performance on AArch64 up to date.
That means we use commits off the following branches:
- TensorFlow: nightly, which is the most recent main that passes the
  nightlies. We don't use main because there's no point us having to deal with
  already known issues.
- oneDNN: 3.7-rc.
- ComputeLibrary: 24.12.

Each commit of `tensorflow-aarch64` is a fixed reference point, both for
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
If other failures are detected (e.g. TensorFlow unit tests) they should be
reported (and fixed if you can!) but they do not have to block the bump.
It is more important that we continue to detect other problems as they arise
than `tensorflow-aarch64` is 100% correct.
Needless to say: **if you care about correctness, do not use this build**.
