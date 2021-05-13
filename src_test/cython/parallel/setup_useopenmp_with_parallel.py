from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import Cythonize

ext_module = Extension(
        "useopenmp_with_parallel",
        ["useopenmp_with_parallel.pyx"],
        extra_compile_args=['-fopenmp'],
        extra_link_args=['-fopenmp'],
   )

setup(
        name = 'OpenMP(parallel print) app',
        cmdclass = {'build_ext': build_ext},
        #ext_modules= [ext_module],
        ext_modules= cythonize(ext_module),
     )

