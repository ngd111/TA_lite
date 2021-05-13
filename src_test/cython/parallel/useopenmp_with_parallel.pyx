from cython.parallel cimport parallel
from cython.parallel import prange
from libc.stdlib cimport malloc, free
cimport openmp

import time

def __cinit__():
    print('init module')

def testpar(int n):
    cdef int i, numthreads
    cdef int * squared
    cdef int * tripled
    cdef size_t size = 10

    with nogil,parallel(num_threads=4):
        numthreads = openmp.omp_get_num_threads()
        squared = <int *>malloc(sizeof(int) * n)
        tripled = <int *>malloc(sizeof(int) * n)

        for i in prange(n,schedule='dynamic'):
            squared[i] = i*i
            tripled[i] = i*i*i + squared[i]
            with gil:
                time.sleep(1)

        free(squared)
        free(tripled)
