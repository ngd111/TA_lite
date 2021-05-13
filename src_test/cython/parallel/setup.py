from distutils.core import setup
from Cython.Build import cythonize

setup(
        name = 'Sumsquare app',
        ext_modules = cythonize("sumsquare.pyx"),
     )
