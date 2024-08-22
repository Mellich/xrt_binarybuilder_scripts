using BinaryBuilder, Pkg

name = "xrt"
version = v"2.17"
sources = [
    GitSource("https://github.com/Xilinx/XRT.git", "a75e9843c875bac0f52d34a1763e39e16fb3c9a7"),
    GitSource("https://github.com/Tencent/rapidjson.git", "ab1842a2dae061284c0a62dca1cc6d5e7e37e346"),
    DirectorySource("$(pwd())/patches")
]

script = raw"""
# Copy license
mkdir -p ${WORKSPACE}/destdir/share/licenses/xrt
cp ${WORKSPACE}/srcdir/XRT/LICENSE ${WORKSPACE}/destdir/share/licenses/xrt

# Install rapidjson
cd ${WORKSPACE}/srcdir/rapidjson
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/srcdir/rapidjson/install \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DRAPIDJSON_BUILD_DOC=No \
    -DRAPIDJSON_BUILD_EXAMPLES=No \
    -DRAPIDJSON_BUILD_TESTS=No \
    -DRAPIDJSON_BUILD_CXX17=Yes
cmake --build build --parallel ${nproc}
cmake --install build

cd ${WORKSPACE}/srcdir/XRT
# Apply patch with missing define
git apply ../huge_shift.patch
# Force use of dynamic boost libs since static are not available
git apply ../no_static_boost_win.patch
# Fix redifinition of data types and missing libs for xclbinutil
git apply ../fix_libs_win.patch

# Statically link to boost
export XRT_BOOST_INSTALL=${WORKSPACE}/destdir

cd src
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${WORKSPACE}/srcdir/rapidjson/install \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build

# Copy folder from xrt to folder to root dest folder
cd ${WORKSPACE}/destdir/
cp -r ./xrt/* ./
rm -rf xrt
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
# Natively, only x86_64 seems to be supported. However, it is possible to build
# XRT for embedded devices with different architectures.
# This will additionally require Qemu_jll as dependency
filter!(p -> arch(p) == "x86_64", platforms)
# XRT supports Windows but requires Visual studio and things like
# TraceLoggingProvider.h which are not available in mingw as far as I know.
# Disabling Windows build for now.
#filter!(p -> Sys.iswindows(p) || (Sys.islinux(p) && libc(p) == "glibc"), platforms)
filter!(p -> Sys.islinux(p) && libc(p) == "glibc", platforms)
products = [
    LibraryProduct("libxrt_coreutil", :libxrt_coreutil),
    LibraryProduct("libxilinxopencl", :libxilinxopencl),
]


dependencies = [
    Dependency("Libuuid_jll", platforms=filter(Sys.islinux, platforms)),
    BuildDependency("boost_jll"),
    Dependency("OpenSSL_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("libdrm_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Ncurses_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("LibYAML_jll", platforms=filter(Sys.islinux, platforms)),
    BuildDependency("OpenCL_Headers_jll"),
    Dependency("protobuf_c_jll", platforms=filter(Sys.islinux, platforms)),
    BuildDependency("ELFIO_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("ocl_icd_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("OpenCL_jll", platforms=filter(Sys.iswindows, platforms)),
    Dependency("LibCURL_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("systemtap_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("systemd_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Libffi_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")