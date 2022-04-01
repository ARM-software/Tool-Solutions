# Changelog
All significant changes to the TensorFlow container builds in
docker/tensorflow-aarch64 will be noted in this log.

Monthly increments are tagged `tensorflow-pytorch-aarch64--rYY.MM`,
where `YY` is the year, and `MM` the month of the increment.

## [Unreleased]

### Added
- Adds docker/tensorflow-aarch64/CHANGELOG.md.
- Adds capability to build TensorFlow with Eigen threadpool for oneDNN+ACL build

### Changed
- Updates oneDNN to v2.6.
- Does not download model in example scripts if was downloaded already

### Removed
- Removes depricated tensorflow/benchmarks from build.

### Fixed
- Fixes git submodule init in SciPy build.
- Fixed updating of weights when training models that have fully connected layers

## [r22.03] 2022-03-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.03/docker/tensorflow-aarch64

### Added
- Includes a patch to make TensorFlow use a global cache for oneDNN primitives.
  this lowers the memory footprint for certain models.
- Adds binary primitive support for oneDNN+ACL builds.

### Changed
- Updates build to use Compute Library 22.02.
- Updates build to use prebuilt wheel for OpenCV-headless.
- Updates the OpenBLAS version.

### Removed
- Removed depricated TensorFlow benchmarks examples from documentation.

### Fixed
- Fixes a bug in the question answering examples.

## [r22.02] 2022-02-11
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.02/docker/tensorflow-aarch64

### Added
- Enables XLA support for TensorFlow.
- Adds Neoverse-V1 and N2 build options.
- Adds tensorflow-addons package.
- Adds SSD-ResNet34 example using, including pre-processing of model to channels-last format.

### Changed
- Updates TensorFlow version to 2.8, which uses oneDNN 2.5 by default.
- Updates OpenBLAS, NumPy and SciPy versions.

## [r22.01] 2022-01-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.01/docker/tensorflow-aarch64

### Changed
- Significant changes to the README documentation.
  Restructures READMEs and adds Getting Started section with more emphasis on
  using pre-built images from Docker Hub.

## [r21.12] 2021-12-20
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.01/docker/tensorflow-aarch64

### Added
- Adds experimental support for spin wait scheduling,
  with thread capping, to the oneDNN+ACL build.
  This reduces the scheduling overhead for Compute Library,
  and improves scaling performance at high core counts.
  It is enabled via the `ARM_COMPUTE_SPIN_WAIT_CPP_SCHEDULER` environment variable.
- Makes it possible to easily extract the finished wheel from the container.
- Enables support for ARM-v8a targets, in addition to Arm-v8.2a and above.

### Changed
- Updates Compute Library version to 21.11.
- Updates tensorflow/benchmarks to use the master branch.

### Fixed
- Various improvements and corrections to the documentation.

## [r21.11] 2021-11-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.11/docker/tensorflow-aarch64

### Added
- Adds support for bf16 “fast maths mode” in inner product and matmul.
- Adds support for `TF_ENABLE_ONEDNN_OPTS` environment variable
  to allow runtime selection of oneDNN backend (only available with --onednn
  build argument).
- Adds Compute Library softmax primitive.
### Changed
- Updates TensorFlow to v2.7.0.
- Improves validation of ACL primtives.

## [r21.10] 2021-10-21
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.10/docker/tensorflow-aarch64

### Added
- Adds support for bf16 "fast-maths mode", enabled via
  `DNNL_DEFAULT_FPMATH_MODE` environment variable.
  Setting to `BF16` or `ANY` will instruct Compute Library to
  dispatch fp32 workloads to bfloat16 kernels
  where hardware support permits
  (Note: this may introduce a drop in accuracy).

### Changed
- Updates oneDNN to v2.4.
- Updates Compute Library to 21.08, with support for bf16 "fast-maths mode"
  and SVE kernels.

## [r21.09] 2021-09-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.09/docker/tensorflow-aarch64

### Added
- Adds Compute Library primtitives for inner product and
  eltwise to oneDNN.

### Changed
- Updates TendorFlow build to use the v2.6 release.
- Ensures caching in TF's primitive factory for inner product
  supports Compute Library primitives.
- Assorted updates to the README files.
- Sets default OpenBLAS build to use a thread limit of 64 threads
  rather than the number of threads available on the host.
  Controlled via parameter in `cpu_info.sh`.

### Removed
- Dissables thread binding for Compute Library primtitives.

### Fixed
- Assorted minor corrections and improvements.

## [r21.08] 2021-08-20
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.08/docker/tensorflow-aarch64

### Added
- Allows GEBP cache sizes used when building with the Eigen backend
  to be set at build-time, via parameters in `cpu_info.sh`.
### Changed
- Updates oneDNN version to 2.3.

## [r21.07] 2021-07-16
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.07/docker/tensorflow-aarch64

### Changed
- Updates TensorFlow to version 2.5.
- Updates Compute Library to version 21.05.
- Updates NumPy version to 1.19.5.
- Updates SciPy version to 1.5.2.
- Adds YAML config files for C++ API examples.

## [r21.06] 2021-06-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.06/docker/tensorflow-aarch64

### Added
- Adds MLCommons BERT benchmarks.
- Adds simple DistilBERT examples.

## [r21.05] 2021-05-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.05/docker/tensorflow-aarch64

### Added
- Adds object detection example.

### Changed
- Updates OS to Ubuntu 20.04.
- Update to Python 3.8.

### Removed
- Removes TF 1.x build option.
- Removes ArmPL dependencies (oneDNN build defaults to Compute Library).

## [r21.04] 2021-04-22
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.04/docker/tensorflow-aarch64
This tag marks the first monthly increment of the TensorFlow container build.

### Added
- Adds vision examples.

### Changed
- Updates oneDNN to v2.2.
- Updated Compute Library to v21.02.

