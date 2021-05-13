cdef class tagger_utils(object):
    #cdef public int32_t addresult(self, int32_t _a, int32_t _b):
    #    return _a + _b

    cdef public list _apply_compound_dictionary(self, list _tokens, dict _compound_dictionary):
        words = [t.split("/", 1)[0] for t in _tokens]

        _2gram = {k:e for k, e in _compound_dictionary.items() if len(k) == 2}
        _3gram = {k:e for k, e in _compound_dictionary.items() if len(k) == 3}

        #cdef list _c_tokens=[]
        _c_tokens=[]
        _c_tokens.extend(_tokens)
        _c_tokens = _tokens

        cdef int64_t i=0
        cdef int32_t N=3
        cdef int64_t start_idx=0
        remove_indice=[]
        for c_words in _3gram.items():
            if (c_words[0][0] in words):
                start_idx = words.index(c_words[0][0])
                try:
                    for i in range(start_idx, len(words)):
                        if (i + N) > len(words):
                            break
                        if (words[i] == c_words[0][0]) and (words[i+1] == c_words[0][1]) and (words[i+2] == c_words[0][2]):
                            remove_indice.extend([idx for idx in range(i+1, i+N)])
                            s_c_words = c_words[1].split("/")
                            words[i] = s_c_words[0]
                            _c_tokens[i] = words[i] + "/" + s_c_words[1]
                except IndexError as e:
                    print('exception: %s, i => %d' % (e.args[0], i))
                    print('words[%d] => %s' % (i, words[i]))
                    print('_c_tokens[%d] => %s' % (i, _c_tokens[i]))
                    raise e

        _c_tokens = [v for i, v in enumerate(_c_tokens) if i not in remove_indice]

        words = [t.split("/", 1)[0] for t in _c_tokens]

        N=2
        remove_indice=[]
        for c_words in _2gram.items():
            if (c_words[0][0] in words):
                start_idx = words.index(c_words[0][0])
                try:
                    for i in range(start_idx, len(words)):
                        if (i + N) > len(words):
                            break
                        if (words[i] == c_words[0][0]) and (words[i+1] == c_words[0][1]):
                            remove_indice.extend([idx for idx in range(i+1, i+N)])
                            s_c_words = c_words[1].split("/")
                            words[i] = s_c_words[0]
                            _c_tokens[i] = words[i] + "/" + s_c_words[1]
                except IndexError as e:
                    print('exception: %s, i => %d' % (e.args[0], i))
                    print('words[%d] => %s' % (i, words[i]))
                    print('_c_tokens[%d] => %s' % (i, _c_tokens[i]))
                    raise e

        _c_tokens = [v for i, v in enumerate(_c_tokens) if i not in remove_indice]  

        return _c_tokens

def apply_compound_dictionary(_tokens, _dic):
    cdef tagger_utils tu
    tu = tagger_utils()
    return tu._apply_compound_dictionary(_tokens, _dic)
