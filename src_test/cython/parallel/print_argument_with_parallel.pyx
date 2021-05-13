cimport cython
from cython.parallel import parallel
from cython.parallel import prange
cimport openmp

import time

def __cinit__():
    print('init module')

cdef void print_filename(int idx) nogil:
    with gil:
        print('in print_filename %d' % idx)
        time.sleep(1)

cdef void print_filename_s(char * _filename) nogil:
    with gil:
        print('in print_filename %s' % _filename)
        time.sleep(1)

def print_filename_python_s(_filename):
    print('in print_filename %s' % _filename)
    time.sleep(1)


@cython.boundscheck(False)
@cython.wraparound(False)
def print_argument(int n):
    cdef int i
    #cdef size_t size = 10

    filenames = []
    for i in range(n):
        filename = 'filename ' + str(i)
        filenames.append(filename)

    print(filenames)

    with nogil,parallel(num_threads=4):
        for i in prange(n, schedule='dynamic'):
            with gil:
                #print_filename(i)
                #print_filename_s(filenames[i])
                print_filename_python_s(filenames[i])


