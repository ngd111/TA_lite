import cython
cimport cython

cdef class return_list:

    @cython.profile(True)
    cpdef public list get_list(self, int n):
        cdef list rlist = [i for i in range(n)]

        return rlist
