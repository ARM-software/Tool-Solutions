cmake -DLOOPUNROLL=ON \
      -DBENCHMARK=ON \
      -DOPTIMIZED=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_FLAGS_RELEASE="-Ofast -ffast-math -DNDEBUG -Wall -Wextra" \
      -DHELIUM=ON \
      -DCMAKE_PREFIX_PATH="/home/user1/AC6/" \
      -DCMAKE_TOOLCHAIN_FILE=../../armac6.cmake \
      -DARM_CPU="cortex-m55" \
      -DEXTBENCH=OFF \
      -DPLATFORM="IPSS" \
      -DDISTANCE=OFF \
      -DBASICMATHSNN=OFF \
      -DCONFIGTABLE=OFF \
      -G "Unix Makefiles" ..

      
