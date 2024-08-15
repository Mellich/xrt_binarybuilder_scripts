using BinaryBuilder

name = "ocl_icd"
version = v"2024.05.08"
sources = [
    GitSource("https://github.com/KhronosGroup/OpenCL-ICD-Loader.git", "861b68b290e76d08e7241608479c16431f529945")
]

script = raw"""
cd ${WORKSPACE}/srcdir/OpenCL-ICD-Loader
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release 
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libOpenCL", "OpenCL"], :libocl_icd),
    ExecutableProduct("cllayerinfo", :cllayerinfo)
]


dependencies = [
    BuildDependency("OpenCL_Headers_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")