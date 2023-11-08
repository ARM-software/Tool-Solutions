# Changelog
All significant changes to the TensorFlow container builds in
docker/tensorflow-aarch64 will be noted in this log.

Monthly increments are tagged `tensorflow-pytorch-aarch64--rYY.MM`,
where `YY` is the year, and `MM` the month of the increment.

## [Unreleased]

### Added

### Changed

### Removed

### Fixed

## [r23.11] 2023-11-08
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.11/docker/tensorflow-aarch64

### Added

### Changed
 - Updated Tensorflow to version v2.14.0.
 - Updated oneDNN to version v3.3.
 - Updated list and content of oneDNN patches.
    - Removed the oneDNN_acl fp32 to bf16 reorder patch,
      as it was merged upstream in v3.3.
    - Added appropriate `#cmakedefine01` for GEMM kernels,
      required by oneDNN v3.3, to the mkl_acl.BUILD file.

### Removed

### Fixed

## [r23.10] 2023-10-11
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.10/docker/tensorflow-aarch64

### Added
 - oneDNN patch to enable JITed BF16 reorders.
 - Tensorflow patch to limit Eigen ThreadPool threads.

### Changed
 - oneDNN updated to v3.2.1
 - Pinned ml_dtypes to 0.2.0 to fix incompatibility with TF 2.14-rc
 - Replaced numpy/scipy builds with pip installed versions.
 - Updated numpy to v1.25.2.
 - Updated scipy to v1.10.1.

### Removed
 - OpenBLAS build removed.

### Fixed

## [r23.09] 2023-09-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.09/docker/tensorflow-aarch64

### Added

### Changed
- Updates Tensorflow to release candidate, Git tag: v2.14.0-rc1.

### Removed

### Fixed

## [r23.08] 2023-08-16
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.08/docker/tensorflow-aarch64

### Added

### Changed
- Updates Tensorflow to unreleased version, Git hash: 59ec4da. This release contains the following changes:
  - Refactored code for reducing MKL overheads by calling into Eigen for small shapes.
  - Heuristics for matmul.
  - Inter scheduler support added.
  - ACL version 23.05.1
  - ACL reorder for select shapes.
  - Remedial fixes moving some ops to Eigen for increased performance.
  - Using ACL instead of GEMM API.
  - Dispatch with heuristics.
  - Tensorflow recursive scheduler
- Increments ML Commons from v0.7 to v2.1.

### Removed
- Support for ssd-resnet34 model in ML Commons removed, due to deprication by ML Commons.
- Patch for optional run_cnn.py wrapper script removed, no longer supported.

### Fixed
- Remedial fixes moving some ops to Eigen for increased performance.
- Fix to specify that format should be any for weights for matmul and inner product.
- Pinned the protobuf version to 4.23.4 to prevent a segfault during inference.

## [r23.07] 2023-07-04
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.07/docker/tensorflow-aarch64

### Added

### Changed

### Removed

### Fixed
- Specifies in TensorFlow that type of weights for matrix multiplication
  and inner product is `any` so that accelerated kernels from ACL are invoked.

## [r23.06] 2023-06-08
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.06/docker/tensorflow-aarch64

### Added
- Adds tensor dilation parameter configuration for acl depthwise convolution.

### Changed
- Updates Compute Library to 23.05.
- Now using Bazel build from Compute Library when building Tensorflow.

### Removed
- Removed ACL Winograd support.

### Fixed

## [r23.05] 2023-05-09
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.05/docker/tensorflow-aarch64

### Added

### Changed
- Updates TensorFlow to v2.12.

### Removed
- Support for building TF Serving removed.

### Fixed

## [r23.04] 2023-04-13
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.04/docker/tensorflow-aarch64

### Added
- Adds patch to divert calls of oneDNN's gemm_api into ACL

### Changed
- Updates base OS image to Ubuntu 22.04.
- Updates Python version from 3.8 to 3.10.
- Updates GCC to v11.
- Scheduler for oneDNN primitives is now recursive, reducing the time taken to distribute work, particularly for high numbers of threads

### Removed

### Fixed

## [r23.03] 2023-03-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.03/docker/tensorflow-aarch64

### Added
 - Adds patch to rewrite node in graph to run with oneDNN primitive or Eigen based on heuristics.

## [r23.02] 2023-02-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.02/docker/tensorflow-aarch64

### Changed
 - Updates oneDNN to version v2.7.3
 - Adds patch to fix threadpool scheduler in oneDNN to make local thread activate and deactivate threadpool

## [r23.01] 2023-01-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.01/docker/tensorflow-aarch64

### Changed
 - Unsets TF_MKL_OPTIMIZE_PRIMITIVE_MEMUSE for TF build to ensure ACL primitives are always cached.

## [r22.12] 2022-12-06
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.12/docker/tensorflow-aarch64

### Added
 - Adds patches to support reorders with padding,

### Changed
 - Updates TensorFlow version to 2.11.0.
 - Updates Compute Library version to 22.11.

## [r22.11] 2022-11-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.11/docker/tensorflow-aarch64

### Fixed
 - Adds patch to fix an issue in ACL when workload sizes are smaller than available threads

## [r22.10] 2022-10-21
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.10/docker/tensorflow-aarch64

### Changed
- Installs tensorflow-io in place of tensorflow-io-gcs-filesystem (which is in turn installed).
- Updates oneDNN to v2.7

### Fixed
- oneDNN uses indirect convolution in fast math mode when input channels require padding.
- ACL uses correct predicate when reading bias in the merge phase of SVE kernels.
- Convolution and matmul oneDNN primitives only cast to BF16 if selected kernel is in fast math mode.
- Correct calculation of multi-stride when fastest changing dimension is padded in fast math mode.

## [r22.09] 2022-09-16
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.09/docker/tensorflow-aarch64

### Added
- oneDNN uses fixed format kernels from Compute Library for convolutions, inner product and matrix multiplication.
- Accelerates depthwise convolution by calling equivalent ACL operation.
- Support for SVE-128 and SVE-256 enabled in JITed eltwise primitives where HW support is available.

### Changed
- Updates Compute Library to v22.08.
- Updates oneDNN to 80d45b77f1a031a99d628b27aeea45b05f16b8b5.
- Updates TensorFlow to v2.10.
- Re-enable oneDNN thread-cap patch in TensorFlow build

### Removed
- AArch64 specific caching of oneDNN primitives in TensorFlow.

### Fixed
- Missing reorder when doing batched matrix multiplication in TensorFlow.
- Fix scope of class that holds reordered weights data in TensorFlow fixed format kernels patch

## [r22.08] 2022-08-12
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.08/docker/tensorflow-aarch64

### Added

### Changed
- Updates pooling patch in TF build with latest changes to https://github.com/oneapi-src/oneDNN/pull/1387.

### Removed
- Removes PR56150 from TF build since this has been abandoned upstream due to a regression.

### Fixed
- Fixes typo in Python examples.

## [r22.07] 2022-07-15
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.07/docker/tensorflow-aarch64

### Added
- Adds improved support for ACL-based postops.

### Changed
- Updates the Compute Library version used for TensorFlow builds from 22.02 to 22.05.
- Updates oneDNN to 70d1198de554e61081147c199d661df049233279.
  This commit includes a number of recent PRs for AArch64.

## [r22.06] 2022-06-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.06/docker/tensorflow-aarch64

### Added
- Adds ACL-based pooling primitive.

### Changed
- Updates TensorFlow to v2.9.1.
- Uses Bazelisk to choose correct Bazel version, rather than picking a specific Bazel release.

### Removed
- Removes GCC 7 & 9 from Tensorflow image.
- Removes superfluous TensorFlow patches.
- Removes OpenMP dependency from the `acl_threadpool` build.

### Fixed
- Applies patches from a number of upstream PRs to fix unit-test failures, see:
  https://github.com/tensorflow/tensorflow/pull/56150
  https://github.com/tensorflow/tensorflow/pull/56218
  https://github.com/tensorflow/tensorflow/pull/56086
  https://github.com/tensorflow/tensorflow/pull/56219
  https://github.com/tensorflow/tensorflow/pull/56371
- Fixes bug in matmul bcast.
- Fixes threadpool impl. to support ACL+threadpool build in TF.
- Fixes a number of TensorFlow unit test failures due to oneDNN.

## [r22.05] 2022-05-06
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.05/docker/tensorflow-aarch64

### Added
- Adds ACL-based PReLU primitive.
- Python vision examples updated to allow use of a local image file.

### Changed

### Removed

### Fixed
- Python vision examples will not download labels and images if they are already present.

## [r22.04] 2022-04-08
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.04/docker/tensorflow-aarch64

### Added
- Adds docker/tensorflow-aarch64/CHANGELOG.md.
- Adds capability to build TensorFlow with Eigen threadpool for oneDNN+ACL build.

### Changed
- Updates oneDNN to v2.6.
- Does not download model in example scripts if it was downloaded already.

### Removed
- Removes deprecated tensorflow/benchmarks from build.

### Fixed
- Fixes git submodule init in SciPy build.
- Fixes weight-updating when training models that have fully connected layers.

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
- Removed deprecated TensorFlow benchmarks examples from documentation.

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
