# Changelog
All significant changes to the PyTorch container builds in
docker/pytorch-aarch64 will be noted in this log.

Monthly increments are tagged `tensorflow-pytorch-aarch64--rYY.MM`,
where `YY` is the year, and `MM` the month of the increment.

## [unreleased]

### Added
 - Work in progress oneDNN patch, [Enable jit conv for 128](https://github.com/uxlfoundation/oneDNN/pull/3022) with ~30% speed up for backward convolutions
 - Add `--wheel-only` flag for only building the torch wheel

### Changed
 - Updates hashes for:
   - PyTorch fc674b45d4d8edfd4c630d89f71ea9f85a2f61f2, 2.8.0.dev20250403 from viable/strict
   - ideep to 719d8e6cd7f7a0e01b155657526d693acf97c2b3 from ideep_pytorch
   - oneDNN to 5de25f354afee38bf2db61f485c729d30f62c611 from main
   - Compute Library to 9033bdacdc3840c80762bc56e8facb87b0e1048e, 25.03 release
   - OpenBLAS to edef2e4441e50e3a2da1920fdbde09101087c43d from main
 - Updates existing WIP patches.
 - Update torchvision from 0.22.0.dev20250305 to a more recent nightly build, 0.22.0.dev20250403

### Removed
 - Removes WIP patches which have now landed in the upstream nightly PyTorch builds.
 - Removes `--tags --force` from git clone command, and adds `--depth=1` to speedup the checkout.

### Fixed

## [r25.03.1] 2025-03-26
https://github.com/ARM-software/Tool-Solutions/tree/r25.03.1

### Added

### Changed
 -Move torch packages to latest stable to fix build error.
  - torchaudio==2.6.0.dev20250305 -> 2.6.0
  - torchdata~=0.7.1 -> 0.11.0
  - torchvision~=0.22.0.dev20250305 -> 0.21.0
  - torchtune==0.6.0.dev20250115 -> 0.5.0

### Removed

### Fixed
- Fix build error due to missing torchtune nightly build
- Fix build error due to auditwheel version change by applying commits from https://github.com/pytorch/pytorch/pull/149471

## [r25.03] 2025-03-14
https://github.com/ARM-software/Tool-Solutions/tree/r25.03

### Added
- Adds work-in-progress PyTorch PRs:
  - https://github.com/pytorch/pytorch/pull/148542 - Enables direct use Compute Library in ATen.
  - https://github.com/pytorch/pytorch/pull/147337 - Enables a fast path for static qlinear via Compute Library directly.
  - https://github.com/pytorch/pytorch/pull/146620 - Enables qint8 and quint8 add via Compute Library directly. Speedup for OMP_NUM_THREADS=1 is ~15x, and ~5.4x for 32 threads.
  - https://github.com/pytorch/pytorch/pull/148197 - Enables oneDNN dispatch for GEMM bf16bf16->bf16.
  - https://github.com/pytorch/pytorch/pull/140159 - Enables gemm-bf16f32/
- Adds work-in-progress oneDNN PRs:
  - https://github.com/uxlfoundation/oneDNN/pull/2838 - Dispatches fpmath_mode::bf16 conv to Compute Library.

### Changed
- Updates hashes for:
  - PyTorch to e555c4d (2.7.0.dev20250305) from viable/strict branch.
  - ideep to 719d8e6  from ideep_pytorch branch.
  - oneDNN to 321c452 from main branch.
  - Compute Library to v25.02.1.
  - OpenBLAS to ef9e3f7 from main.
- Updates work-in-progress PyTorch PRs.
- Updates torchaudio to 2.6.0.dev20250305.
- Updates torchvision to 0.22.0.dev20250305.
- Dockerfile now upgrades pip before installing Python packages.
- git-shallow-clone function now supports cloning by tag as well as hash.

### Removed
- Removes patches which have now been merged into the upstream branches.
- Removes static_quantize_conv example since https://github.com/pytorch/pytorch/pull/141127 is no longer included in the build.

### Fixed

## [r25.02] 2025-02-11
https://github.com/ARM-software/Tool-Solutions/tree/pytorch-aarch64--r25.02

### Added
- Adds work-in-progress PyTorch PRs:
  - https://github.com/pytorch/pytorch/pull/145942 - Enable qlinear_dynamic path for AArch64 through Arm Compute Library directly. Gives ~15% speed up on approach in Tool Solutions 24.12.
  - https://github.com/pytorch/pytorch/pull/146476 - Improve KleidiAI 4 bit kernel performance. Greater than 10% performance improvment when calling INT4 KleidiAI kernels
  - https://github.com/pytorch/pytorch/pull/143666 - Extend Vec backend with SVE BF16 (gives ~2.8x improvement for aten::addmm in autocast=bf16 mode).
- Adds work-in-progress oneDNN PRs:
  - https://github.com/oneapi-src/oneDNN/pull/2502 - cpu: aarch64: ip: Allow bf16 for ACL inner product. Gives speedups of ~170x for BERT_pytorch and ~160x for alexnet using bf16 compile mode.
- Minor improvements to build process and logging.
- OpenBLAS build from source at 1b85b6a396c94e78c9ba14aafcdfd5c5da5a8bb2 from develop branch.
  This includes https://github.com/OpenMathLib/OpenBLAS/pull/5108 to add SBGEMM support for 256bit SVE.

### Changed
- Updates hashes for:
  - PyTorch to 8d4926e30a944320adf434016129cb6788eff79b (2.7.0.dev20250115), from viable/strict
  - ideep to e026f3b0318087fe19e2b062e8edf55bfe7a522c, from ideep_pytorch
  - oneDNN to 0fd3b73a25d11106e141ddefd19fcacc74f8bbfe, from main
  - Arm Compute Library to 6acccf1730b48c9a22155998fc4b2e0752472148. from main
  - Torchao to 2e032c6b0de960dee554dcb08126ace718b14c6d, from main
- Updates work-in-progress PyTorch PRs:
  - Replaces https://github.com/pytorch/pytorch/pull/139753 with https://github.com/pytorch/pytorch/pull/145486
- Updates transformers to version 4.48.2 and tokenizers to version 0.21
- Updates KleidiAI submodule to ef685a13cfbe8d418aa2ed34350e21e4938358b6, from main.
- Removed packed linear function as this is now done automatically with `with torch.no_grad()`

### Removed
- Removes patches that are now merged upstream.
- Removes https://github.com/pytorch/pytorch/pull/139387 - Add prepacking for linear weights. Performance gains better realised by ideep reorder caching.

### Fixed
- Addition of https://github.com/pytorch/pytorch/pull/145486 fixes illigal instruction on non-SVE targets.

## [r24.12] 2024-12-20
https://github.com/ARM-software/Tool-Solutions/tree/pytorch-aarch64--r24.12

### Added
- Adds torchao.
- Adds work-in-progress PyTorch PRs:
  - 142391 8373846f441381a56e7abd905af84102aa52fc7b - parallelize sort;
  - 139387 e5e5d29d6bab882540e36e44a3a75bd187fcbb62 - Add prepacking for linear weights;
  - 139387 19423aaa1af154e1d47d8acf1e677dff727da5aa - Add prepacking for linear weights;
  - 140159 9463c3261f57c42a952f1ba95633833cb1c561fc - cpu: aarch64: enable gemm-bf16f32.
  - 134124 1c0ef38138d8621ab4a044860404fbf01c7504a6
          80d263f5343806d3169f5c180f23cfe975264bdf
          3c10c2b55eecd2f9316b845ff697519639601527
          6d178afd7d82d2ed12b7734e7e2b350a2d332e1c - 4 bit dynamic quantization matmuls & KleidiAI Backend.
- Adds libtbb to Docker to support parallel sort optimisations.
- Adds 4bit LLM Torchchat and Transformers examples.

### Changed
- Renames `docker` folder to `ML-Frameworks` as part of the removal of legacy content from the repo.
- Updates apply-github-patch to make it more tollerant of upstream changes.
- Removed the dependency on pytorch/builder and use pytorch/.ci scripts for building pytorch.
- Updates hashes for:
  - PyTorch, to 8d4926e30a944320adf434016129cb6788eff79b (from viable/strict branch);
  - iDeep, to e026f3b0318087fe19e2b062e8edf55bfe7a522c (from ideep_pytorch branch);
  - oneDNN, to 0fd3b73a25d11106e141ddefd19fcacc74f8bbfe (from main branch);
  - Arm Compute Library, to 6acccf1730b48c9a22155998fc4b2e0752472148 (from main branch).
- Updates PyTorch dependencies:
  - torchvision updated to 0.22.0.dev20241218;
  - torchaudio updated to 2.6.0.dev20241218.
- Updates build environment to manylinux2_28_aarch64.
  Note: this updates the GCC version from 10 to 11 with performance improvements of 5-10% in many cases.
- Add examples/pack_linear_weights.py.

### Removed

### Fixed

## [r24.11] 2024-11-15
https://github.com/ARM-software/Tool-Solutions/tree/pytorch-aarch64--r24.11/docker/pytorch-aarch64

### Added
- Optimizations for dynamic and static quantization
- Caching of reordered weights in eager mode
- Improved multithreading for interleaved kernels

### Changed
- Now tracking close to the main of the whole stack
- Updated ComputeLibrary to 24.11.dev-fa7806d
- Updated oneDNN to 3.7.dev-dd33e126
- Updated iDeep to 3.7.dev-77d4b35
- Updated PyTorch to 2.6.dev-3179eb1
- Updated OpenBLAS to 0.3.28

### Removed
- Removed MLCommons examples and patches
- Removed torchtext example
- Removed RetinaNet object detection
- Removed all inline patches, work in progress features should now be applied
  from PRs using wget. Removed patches have been merged upstream (and now picked
  up by new versions of software components) or are now included via wget in
  `./get-source.sh`

## [r24.08] 2024-08-05
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r24.08/docker/pytorch-aarch64

### Added
- Build with tcmalloc
- PoC SVE implementation for embedding_lookup_idx
- Relaxed precision float32 matmul fixes
- Patch to remove matmul primitive caching in ideep

## [r24.07] 2024-07-01
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r24.07/docker/pytorch-aarch64

### Added
- ACL and oneDNN patches to enable PyTorch static quantization for convolution.
- ACL patch for mixed sign GEMM support
- Modified oneDNN to v3.5
- oneDNN patch for tanh based GELU on aarch64

### Changed
- Update ACL to Git hash: c2237ec
- Added stateless matmul APIs to ACL and oneDNN
- Added .gitignore

### Removed
- Removed fixed cython versions in Dockerfile

## [r24.06] 2024-06-01
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r24.06/docker/pytorch-aarch64

### Added

### Changed
- Updated PyTorch to v2.3.0
- Updated ideep to Git Hash: 55ca019
- Updated oneDNN to Git Hash: eb013e3, which includes among other things:
    - Removing fall through to oneDNN reference implementation for depthwise convolution when padding greater than kernel
- Updated ACL to Git Hash: 4c3f716
- Updated torchtext to v0.18.0
- Updated OpenBLAS to v0.3.27

### Removed
- All patches that were merged upstream:
  - acl_bf16_dispatch.patch
  - acl_dynamic_quantization.patch
  - acl_in_place_sum.patch
  - acl_parallelize_im2col.patch
  - onednn_acl_fp32_bf16_reorder.patch
  - onednn_acl_reorder.patch
  - onednn_add_Acdb8a_and_Acdb4a_acl_reorders.patch
  - onednn_bf16_matmul_kernel.patch
  - onednn_dynamic_quantization.patch
  - onednn_fp32_bf16_reorder.patch
  - onednn_in_place_sum.patch
  - onednn_stop_linking_to_arm_core_library.patch
  - onednn_update_conv2dinfo_constructor.patch

### Fixed

## [r24.03] 2024-04-04
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r24.03/docker/pytorch-aarch64

### Added
- oneDNN patch for indirect conv enablement
- TorchAudio version 2.2.1
- Simple quantized example: `quantized_linear.py`
- BERT Large and dynamic quantization flag to `answer_questions.py`

### Changed
- Updated oneDNN version to v3.3.5
- Updated PyTorch version to v2.2.1
- Updated Compute Libray to v24.02
- Updated TorchVision version to v0.17.1
- Updated TorchData version to v0.7.1
- Updated TorchText version to v0.17.1
- Updated ideep to pytorch-rls-v3.3.5
- Updated build scripts for: TorchData, TorchText
- ACL patch for im2col parallelization
- ACL patch which adds a new NEON fixed format hybrid kernel
  with max height of 6 for accumulation and updates heuristics
- Acdb8a/Acdb4a reorders

### Removed
- XLA option
- acl_fp32_bf16_reorder patch as it's in ACL v24.02

### Fixed

## [r24.02.1] 2024-03-06
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r24.02.1/docker/pytorch-aarch64

### Added

### Changed
- Downgrade OpenBLAS version to v0.3.24

### Removed

### Fixed

## [r24.02] 2024-02-28
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r24.02/docker/pytorch-aarch64

### Added
- ACL and oneDNN patches to add matmul kernel to enable bf16 to bf16 operations
  via PyTorch® autocast() function.

### Changed
- Updated OpenBLAS version to v0.3.26

### Removed

### Fixed

## [r24.01] 2024-01-23
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r24.01/docker/pytorch-aarch64

### Added
- ACL and oneDNN patches for in place sum

### Changed
- Updated oneDNN version to v3.3.4
- Updated pytorch version to v2.2.0-rc8
- Updated ideep to Git Hash: 087f41a

### Removed
 - onednn_acl_threadcap.patch as it causes a regression

### Fixed

## [r23.12] 2023-12-15
https://github.com/ARM-software/Tool-Solutions/tree/tensorflow-pytorch-aarch64--r23.12/docker/pytorch-aarch64

### Added
- ACL-based FP32 to BF16 reorders for select shapes
- Support for dynamic quantisation
- Parallelisation of depthwise convolution when batch size is greater than one and width is narrow

### Changed
- Updated oneDNN to v3.3
- Updated Compute Library to v23.08
- Updated ideep to Git Hash: d0c2278
- Refreshed oneDNN patches to be consistent with TensorFlow build.

### Removed

### Fixed
- `nn.Linear.forward` error when `out_features` equals to 1

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
