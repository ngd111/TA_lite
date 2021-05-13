from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_module = Extension(
        "print_argument_with_parallel2",
        ["print_argument_with_parallel2.pyx"],
        extra_compile_args=['-fopenmp'],
        extra_link_args=['-fopenmp'],
   )

setup(
        name = 'Print(parallel)2 app',
        cmdclass = {'build_ext': build_ext},
        ext_modules= [ext_module],
     )

