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
patch -p1 < ../tf_dnnl_decoupling.patch


# Env vars used to avoid interactive elements of the build.
export HOST_C_COMPILER=(which gcc)
export HOST_CXX_COMPILER=(which g++)
export PYTHON_BIN_PATH=(which python)
export USE_DEFAULT_PYTHON_LIB_PATH=1
export CC_OPT_FLAGS=""
export TF_ENABLE_XLA=0
export TF_NEED_GCP=0
export TF_NEED_S3=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_CUDA=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_MPI=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_ROCM=0

./configure

extra_args=""
if [[ $BZL_RAM ]]; then extra_args="$extra_args --local_ram_resources=$BZL_RAM"; fi
if [[ $NP_MAKE ]]; then extra_args="$extra_args --jobs=$NP_MAKE"; fi

if [[ $DNNL_BUILD ]]; then 
  echo "$DNNL_BUILD build"
  bazel build $extra_args \
    --define=build_with_mkl_dnn_only=true --define=build_with_mkl=true \
    --define=tensorflow_mkldnn_contraction_kernel=1 \
    --copt="-mtune=native" --copt="-march=armv8-a" --copt="-O3" --copt="-fopenmp" \
    --cxxopt="-mtune=native" --cxxopt="-march=armv8-a" --cxxopt="-O3" --cxxopt="-fopenmp" \
    --linkopt="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" --linkopt="-fopenmp" \
    --config=noaws --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
    //tensorflow/tools/pip_package:build_pip_package
else
   echo "Eigen-only build"
   bazel build $extra_args --define tensorflow_mkldnn_contraction_kernel=0 \
    --copt="-mtune=native" --copt="-march=armv8-a" --copt="-O3" \
    --cxxopt="-mtune=native" --cxxopt="-march=armv8-a" --cxxopt="-O3" \
    --copt="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" \
    --config=noaws --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
    //tensorflow/tools/pip_package:build_pip_package
fi

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
