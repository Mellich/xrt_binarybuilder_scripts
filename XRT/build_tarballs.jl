using BinaryBuilder, Pkg

name = "xrt"
version = v"2.17"
sources = [
    GitSource("https://github.com/Xilinx/XRT.git", "a75e9843c875bac0f52d34a1763e39e16fb3c9a7"),
    DirectorySource("$(pwd())/XRT_patches")
]

script = raw"""
cd ${WORKSPACE}/srcdir/XRT
# Apply patch with missing define
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
    #Dependency("OpenCL_jll"),
    Dependency("protobuf_c_jll"),
    Dependency(PackageSpec(; url="https://github.com/Mellich/ELFIO_jll.jl.git", rev="main")),
    Dependency(PackageSpec(; url="https://github.com/Mellich/ocl_icd_jll.jl.git", rev="main")),
    Dependency(PackageSpec(; url="https://github.com/Mellich/rapidjson_jll.jl.git", rev="main")),
    Dependency("LibCURL_jll"),
    Dependency(PackageSpec(; url="https://github.com/Mellich/systemtap_jll.jl.git", rev="main")),
    Dependency("systemd_jll")
]

#build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")