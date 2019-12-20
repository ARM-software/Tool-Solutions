#!/usr/bin/env bash
set -euo pipefail

cd $PACKAGE_DIR
readonly package=tensorflow
readonly version=$TF_VERSION
readonly src_host=https://github.com/tensorflow
readonly src_repo=tensorflow

# Clone tensorflow and benchmarks
git clone ${src_host}/${src_repo}.git
cd ${src_repo}
git checkout v$version -b v$version

# Apply path to allow use of newer Bazel build.
patch -p1 < ../tensorflow.patch

# The following selections are piped through to configure...
# TODO: This can be replaced with env vars picked up by configure.py

python_loc='\n' #  (use default)
python_site_packages_loc='\n' #  (use default)
xla_support=n
opencl_sycl_support=n
rocm_support=n
cuda_support=n
download_clang=n
mpi_support=n
opt_flags='\n' # (none, these will be passed to Bazel build later)
echo -e   "${python_loc}${python_site_packages_loc}${xla_support}${opencl_sycl_support}${rocm_support}${cuda_support}${download_clang}${mpi_support}${opt_flags}" | ./configure

extra_args=""
if [[ $BZL_RAM ]]; then extra_args="$extra_args --local_ram_resources=$BZL_RAM"; fi
if [[ $NP_MAKE ]]; then extra_args="$extra_args --jobs=$NP_MAKE"; fi

bazel build $extra_args --define  tensorflow_mkldnn_contraction_kernel=0 --copt="-mtune=native" --copt="-march=armv8-a" --copt="-O3" \
  --copt="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" \
  --config=noaws --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" //tensorflow/tools/pip_package:build_pip_package  

./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./wheel-TF$TF_VERSION-py$PY_VERSION-$CC

pip install $(ls -tr wheel-TF$TF_VERSION-py$PY_VERSION-$CC/*.whl | tail)

# Check the installation was sucessfull
cd $HOME
python -c 'import tensorflow; print(tensorflow.__version__)' > version.log

if grep -qx $version version.log; then
  echo "TensorFLow $TF_VERSION package installed."
  # Clean up Bazel cache
else
  echo "Tensorflow package installation failed."
  exit 1
fi
rm $HOME/version.log
