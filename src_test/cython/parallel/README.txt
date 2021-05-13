# Cython compile(sumsquare.pyx compile)
python setup.py build_ext --inplace

# with nogil and openMP (no parallel)
python setup_useopenmp.py build_ext --inplace

# with parallel.prange to support parallel
python setup_useopenmp_with_parallel.py build_ext --inplace

# with parallel.prange to support parallel(print argument(filename))
python setup_print_argument_with_parallel.py build_ext --inplace
