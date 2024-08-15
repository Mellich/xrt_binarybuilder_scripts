using BinaryBuilder

name = "xrt"
version = v"2.17"
sources = [
    GitSource("https://github.com/Xilinx/XRT.git", "a75e9843c875bac0f52d34a1763e39e16fb3c9a7"),
    GitSource("https://github.com/cdkey/systemtap.git", "cbb34b7244ba60cb0904d61dc9167290855106aa"),
    GitSource("https://github.com/serge1/ELFIO.git", "8ae6cec5d60495822ecd57d736f66149da9b1830"),
    GitSource("https://github.com/OCL-dev/ocl-icd.git", "fdde6677b21329432db8b481e2637cd10f7d3cb2"),
    GitSource("https://github.com/Tencent/rapidjson.git", "f54b0e47a08782a6131cc3d60f94d038fa6e0a51"),
    DirectorySource("$(pwd())/XRT_patches")
]

script = raw"""
apk add gettext ruby

# Install RapidJSON headers
cd ${WORKSPACE}/srcdir/rapidjson
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
    -DRAPIDJSON_BUILD_DOC=No -DRAPIDJSON_BUILD_EXAMPLES=No -D RAPIDJSON_BUILD_TESTS=No -DRAPIDJSON_BUILD_CXX17=Yes -DRAPIDJSON_BUILD_CXX11=No 
cmake --build build --parallel ${nproc}
cmake --install build

# Build and install ELFIO
cd ${WORKSPACE}/srcdir/ELFIO
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build

# Build and install OpenCL ICD
cd ${WORKSPACE}/srcdir/ocl-icd
./bootstrap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j all
make install

# Build and install Systemtap
cd ${WORKSPACE}/srcdir/systemtap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j all
make install

# Install XRT
cd ${WORKSPACE}/srcdir/XRT
git apply ../huge_shift.patch
cd src
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build

# Copy folder from xrt to folder to root dest folder
cp -r ../../../destdir/xrt/* ../../../destdir/
"""

#platforms = supported_platforms()
platforms = [Platform("x86_64", "linux")]
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libxrt_coreutil", :libxrt_coreutil),
    LibraryProduct("libxilinxopencl", :libxilinxopencl),
    #ExecutableProduct("fooifier", :fooifier),
]


dependencies = [
    Dependency("Libuuid_jll"),
    Dependency("boost_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("libdrm_jll"),
    Dependency("Ncurses_jll"),
    Dependency("LibYAML_jll"),
    BuildDependency("OpenCL_Headers_jll"),
    Dependency("OpenCL_jll"),
    Dependency("protobuf_c_jll"),
    Dependency("Elfutils_jll"),
    Dependency("LibCURL_jll"),
    Dependency("systemd_jll")
]

#build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")