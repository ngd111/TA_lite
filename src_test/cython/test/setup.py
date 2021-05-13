# COmpile a cython file (.pyx) in the directory
from distutils.core import setup
from Cython.Build import cythonize

setup(name = 'Cython Library', ext_modules = cythonize("*.pyx"))
