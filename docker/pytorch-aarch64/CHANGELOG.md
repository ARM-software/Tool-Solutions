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

