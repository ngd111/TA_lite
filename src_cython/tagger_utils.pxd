from libc.stdint cimport int32_t, int64_t

cdef class tagger_utils:
    #cdef public int32_t addresult(self, int32_t _a, int32_t _b)
    cdef public list _apply_compound_dictionary(self, list _tokens, dict _compound_dictionary)
