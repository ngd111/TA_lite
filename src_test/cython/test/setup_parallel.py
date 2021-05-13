# COmpile a cython file (.pyx) in the directory
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

ext_modules = [
        Extension(
            "parallel_pow",
            ["parallel_pow.pyx"],
            extra_compile_args=['-fopenmp'],
            extra_link_args=['-fopenmp'],
            )
        ]

setup(
        name = 'hello-parallel-world', 
        ext_modules = cythonize(ext_modules),
     )
