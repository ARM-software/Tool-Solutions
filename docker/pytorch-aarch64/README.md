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

# General optimization guidelines

## oneDNN runtime flags

- `DNNL_DEFAULT_FPMATH_MODE`: setting the environment variable `DNNL_DEFAULT_FPMATH_MODE` to `BF16` or `ANY` will instruct ACL to dispatch fp32 workloads to bfloat16 kernels where hardware support permits. _Note: this may introduce a drop in accuracy._

## PyTorch runtime flags

We recommend running with the following run time flags and using tcmalloc to handle memory allocations in PyTorch for better performance.

- TORCHINDUCTOR_CPP_WRAPPER=1 - reduces Python overhead within the graph for torch.compile
- TORCHINDUCTOR_FREEZING=1    - Freezing will attempt to inline weights as constants in optimization

```
LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libtcmalloc.so.4  TORCHINDUCTOR_CPP_WRAPPER=1  TORCHINDUCTOR_FREEZING=1  OMP_NUM_THREADS=16  python <your_model_script>.py
```
