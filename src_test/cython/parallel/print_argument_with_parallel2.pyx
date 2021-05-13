from os import listdir
from os.path import isfile, join
cimport cython
from cython.parallel import parallel, prange
#cimport openmp

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
def do_tagging(_filename_list):
    cdef int i
    cdef int n

    n = len(_filename_list)

    with nogil,parallel(num_threads=4):
        for i in prange(n, schedule='dynamic'):
            with gil:
                print_filename_python_s(_filename_list[i])


@cython.boundscheck(False)
@cython.wraparound(False)
def print_argument(int n):
    #cdef size_t size = 10

    while(True != False):
        print('-- Start gathering file list --')

        filenames = [f for f in listdir('../../../data/news_data/') if isfile(join('../../../data/news_data/',
            f)) if f[0:4] == 'news']

        if len(filenames) > 0:
            print('-- Start tagging --')
            do_tagging(filenames)
            print('-- End tagging --')
        time.sleep(5)


