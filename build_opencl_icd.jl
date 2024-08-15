using BinaryBuilder

name = "ocl_icd"
version = v"2.3.2"
sources = [
    GitSource("https://github.com/OCL-dev/ocl-icd.git", "fdde6677b21329432db8b481e2637cd10f7d3cb2"),
]

script = raw"""
#apk add gettext ruby
apk add ruby

# Build and install OpenCL ICD
cd ${WORKSPACE}/srcdir/ocl-icd
./bootstrap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j all
make install

"""

platforms = supported_platforms()

products = [
    FileProduct("include/ocl_icd.h", :ocl_icd_h)
    LibraryProduct("libOpenCL", :libocl_icd)
]


dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")