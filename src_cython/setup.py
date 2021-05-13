from distutils.core import setup
from Cython.Build import cythonize

setup(
        name = 'TA Library',
        ext_modules = cythonize("*.pyx")
     )
