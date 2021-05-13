from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_module = Extension(
        "tagger_utils_interface",
        ["tagger_utils_interface.pyx"],
        extra_compile_args=['-fopenmp'],
        extra_link_args=['-fopenmp'],
   )

setup(
        name = 'cdef class module connector',
        cmdclass = {'build_ext': build_ext},
        ext_modules= [ext_module],
     )

