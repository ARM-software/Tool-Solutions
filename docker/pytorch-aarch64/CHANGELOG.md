# Changelog
All significant changes to the PyTorch container builds in
docker/pytorch-aarch64 will be noted in this log.

Monthly increments are tagged `tensorflow-pytorch-aarch64--rYY.MM`,
where `YY` is the year, and `MM` the month of the increment.

## [Unreleased]

### Added

### Changed

### Removed

### Fixed

## [r23.11] 2023-11-08
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.11/docker/pytorch-aarch64

### Added

### Changed
 - Updated pytorch to version 2.1.0.
 - Updated torchxla to version 2.1.0.
 - Updated torchtext to version 0.16.0.
 - Updated torchvision to version 0.16.0.
 - Updated torchdata to version 0.7.0.
 - Updated oneDNN to version 3.1.1.
 - Updated the list/content of oneDNN patches for version 3.1.1:
    - Remove the jit_unit_reorder patches as they were merged upstream;
    - Updated content of onednn_acl_fixed_format patch;
    - Updated content of the onednn_acl_remove_winograd patch.
 - Pinned onnx package to version 1.15.0 to avoid
   error in numpy due to unsupported method, support
   stopped in numpy 1.23.4.

### Removed

### Fixed

## [r23.10] 2023-10-11
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.10/docker/pytorch-aarch64

### Added

### Changed
 - Replaced numpy/scipy builds with pip installed versions.
 - Updates numpy to v1.25.2.
 - Updates scipy to v1.10.1.

### Removed

### Fixed
 - Fixes numpy array load bug in MLCommons vision examples.

## [r23.09] 2023-09-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.09/docker/pytorch-aarch64

### Added

### Changed

### Removed

### Fixed
 - Fixed a bug in the build.sh script to use the `tag` argument when building any pytorch image.
 - Pins transformers to v4.32.1 to avoid runtime failure when built with `--xla`.

## [r23.08] 2023-08-16
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.08/docker/pytorch-aarch64

### Added
- Adds support for the RetinaNet model to ML Commons.

### Changed
- Increments ML Commons from v0.7 to v2.1.

### Removed
- Support for ssd-resnet34 model in ML Commons removed, due to deprication by ML Commons.

### Fixed

## [r23.07] 2023-07-04
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.07/docker/pytorch-aarch64

### Added

### Changed

### Removed

### Fixed

## [r23.06] 2023-06-08
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.06/docker/pytorch-aarch64

### Added
- Adds tensor dilation parameter configuration for acl depthwise convolution.

### Changed
- Updates the Compute Library version to 23.05.
- Refreshes oneDNN patches to be consistent with TensorFlow build.

### Removed

### Fixed

## [r23.05] 2023-05-09
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.05/docker/pytorch-aarch64

### Added

### Changed
- Increments PyTorch version from 1.13 to 2.0.
- Increments PyTorch XLA version from 1.13 to 2.0.

### Removed
- MLCommons RNNT example removed from examples/README.md due to incompatability with PyTorch 2.0.

### Fixed

## [r23.04] 2023-04-13
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.04/docker/pytorch-aarch64

### Added

### Changed
- Updates base OS image to Ubuntu 22.04.
- Updates Python version from 3.8 to 3.10.
- Updates GCC to v11.

### Removed

### Fixed

## [r23.03] 2023-03-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.03/docker/pytorch-aarch64

## [r23.02] 2023-02-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.02/docker/pytorch-aarch64

## [r23.01] 2023-01-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.01/docker/pytorch-aarch64

### Added
 - Fixed format kernels in oneDNN and ACL.
 - Convolution caching at PyTorch level.
 - Call oneDNN matrix multiplication for BLAS operation when LHS is transposed, but not RHS.
 - Jitted reorder when destination tensor is BF16.

## [r22.12] 2022-12-06
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.12/docker/pytorch-aarch64

### Changed
 - Updates Compute Library version to 22.11.

## [r22.11] 2022-11-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.11/docker/pytorch-aarch64

### Changed
- Updates PyTorch and PyTorch-xla to v1.13.
- Updates oneDNN to v2.7.
- Updates TorchVision to v0.14.
- Updates TorchText to v0.14.
- Updates TorchData to v0.5.

### Fixed
 - Adds patch to fix an issue in ACL when workload sizes are smaller than available threads

## [r22.10] 2022-10-21
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.10/docker/pytorch-aarch64

## [r22.09] 2022-09-16
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.09/docker/pytorch-aarch64

### Added

### Changed
- Updates Compute Library to v22.08.

### Removed

### Fixed

## [r22.08] 2022-08-12
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.08/docker/pytorch-aarch64

## [r22.07] 2022-07-15
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.07/docker/pytorch-aarch64

### Added
- Adds torchdata build script.
- Adds --xla build option to include torch-xla wheel in pytorch image (experimental).

### Changed
- Updates the Compute Library version used for PyTorch builds from 22.02 to 22.05.
- Updates PyTorch to v1.12.0, torchvision to v0.13.0, torchtext to v0.13.0 and torchdata to 0.4.0.
- Updates cmake version to 3.23.2.

## [r22.06] 2022-06-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.06/docker/pytorch-aarch64

### Added
- Adds torchdata package.

### Changed
- Updates PyTorch to v1.11.0, torchvision to v0.12.0, and torchtext to v0.12.0.

### Removed
- Removes dependency on Arm Optimized Routines from PyTorch image.
- Removes GCC 7 from PyTorch image.
- Removes GCC 9 from PyTorch image.

### Fixed

## [r22.05] 2022-05-06
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.05/docker/pytorch-aarch64

### Added
- Python vision examples updated to allow use of a local image file.

### Changed

### Removed

### Fixed
- Python vision examples will not download labels and images if they are already present.

## [r22.04] 2022-04-08
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.04/docker/pytorch-aarch64

### Added
- Adds docker/pytorch-aarch64/CHANGELOG.md.

### Changed
- Updates oneDNN to v2.6.
- Does not download model in example scripts if it was downloaded already.

### Fixed
- Fixes git submodule init in SciPy build.

## [r22.03] 2022-03-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.03/docker/pytorch-aarch64

### Added
- Retains finished wheel for easy extraction from final image.

### Changed
- Updates build to use Compute Library 22.02.
- Updates build to use prebuilt wheel for OpenCV-headless.
- Updates the OpenBLAS version.

### Fixed
- Fixes a bug in the question answering examples.

## [r22.02] 2022-02-11
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.02/docker/pytorch-aarch64

### Added
- Adds Neoverse-V1 and N2 build options.

### Changed
- Updates oneDNN version to 2.5.
- Updates OpenBLAS, NumPy and SciPy versions.

## [r22.01] 2022-01-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r22.01/docker/pytorch-aarch64

### Changed
- Significant changes to the README documentation.
  Restructures READMEs and adds Getting Started section with more emphasis on
  using pre-built images from Docker Hub.

## [r21.12] 2021-12-20
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.12/docker/pytorch-aarch64

### Changed
- Updates Compute Library version to 21.11.

### Fixed
- Various improvements and corrections to the documentation.

## [r21.11] 2021-11-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.11/docker/pytorch-aarch64
### Changed
- Updates PyTorch version to v1.10.0.
- Includes working RNNT example based on MLCommons.

## [r21.10] 2021-10-21
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.10/docker/pytorch-aarch64

### Added
- Includes support for torch.fft with pocketFFT backend.
- Adds torchaudio module.

### Changed
- Updates oneDNN to v2.4.
- Updates Compute Library to 21.08.

## [r21.09] 2021-09-17
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.09/docker/pytorch-aarch64

### Added
- Adds support for pytorch native ResNet50 model.
- Adds torchtext, with example.

### Changed
- Assorted updates to the README files.
- Sets default OpenBLAS build to use a thread limit of 64 threads
  rather than the number of threads available on the host.
  Controlled via parameter in `cpu_info.sh`.
- Assorted minor corrections and improvements.

## [r21.08] 2021-08-20
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.08/docker/pytorch-aarch64

### Changed
- Updates oneDNN version to 2.3.

## [r21.07] 2021-07-16
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.07/docker/pytorch-aarch64

### Changed
- Updates PyTorch to version 1.9.
- Updates Compute Library to version 21.05.

## [r21.06] 2021-06-18
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.06/docker/pytorch-aarch64

### Added
- Adds ML Commons BERT benchmarks.
- Adds simple DistilBERT examples.
- Adds C++ API examples.

## [r21.05] 2021-05-14
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.05/docker/pytorch-aarch64

### Added
- Adds object detection example.

### Changed
- Updates OS to Ubuntu 20.04.
- Update to Python 3.8.

## [r21.04] 2021-04-22
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r21.04/docker/pytorch-aarch64
This tag marks the first monthly increment of the PyTorch container build.

### Added
- Adds vision examples.

### Changed
- Updates oneDNN to v2.2.
- Updates Compute Library to v21.02.
