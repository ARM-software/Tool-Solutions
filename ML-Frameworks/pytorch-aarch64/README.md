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

This [component](https://github.com/ARM-software/Tool-Solutions/tree/master/docker/pytorch-aarch64) of [ARM-Software's](https://github.com/ARM-software) [Tool Solutions](https://github.com/ARM-software/Tool-Solutions) repository provides scripts to build a wheel and a Docker image containing [PyTorch](https://www.pytorch.org/) and dependencies for the [Armv8-A architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile), as well as a selection of [examples and benchmarks](./examples/README.md).

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

### Examples

See [examples README.md](./examples/README.md).
