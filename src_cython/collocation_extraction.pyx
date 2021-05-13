# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube 2017
    Writer : Jin Kak, Jung
    Revision History :
        First released on March, 31, 2017
"""

from nltk import collocations
from collections import defaultdict
cimport cython
import cython
from utils import log

cdef class collocation_extraction(object):

    cdef object measures
    cdef object logger

    cdef list tag_filter

    #def __cinit__(self):
    def __init__(self):
        #if isinstance(_logger_object, log) == False:
        #    raise TypeError('_logger_object is not utils.log object')

        self.measures = collocations.BigramAssocMeasures()
        self.tag_filter = ['NNG','NNP','NP']
        print("collocation object initialized")

    def __dealloc__(self):
        print("collocation object deinitialized")

    """
        parameters : 
            _result_list : list[tuple(tuple(value, value), score)] ; The score must be a number(float ...)
                ex) [((u'한국',u'증시'),3.233), ((u'일본',u'하락'),1.233)]
        returns : 
            conv_dic : defaultdict{value:list[value, value, ...]}
                ex) {u'한국':[u'증시',u'독도'], u'일본':[u'하락','상승장']}
    """
    def _convert_results_horizontally(self, _result_list):
        if isinstance(_result_list, list) == False:
            raise TypeError('_result_list parameter type is not list')

        conv_dic = defaultdict(list)
        for c in _result_list:
            if c[0][0] != c[0][1]:
                conv_dic[c[0][0]].append(c[0][1])

        return conv_dic


    @cython.profile(True)
    cpdef object extraction(self, list _tokens, int _min_df = 2):
        if type(_tokens) != list:
            raise TypeError('_tokens must be a list type')
        
        _tokens = [t for t in _tokens if t.split('/')[1] in self.tag_filter]

        #if len(_tokens) < 10:
        #    raise ValueError('_tokens length is too small to be calculated')

        if _min_df < 1:
            raise ValueError('_min_df must be larger than 0')

        try:
            finder = collocations.BigramCollocationFinder.from_words(_tokens)
            finder.apply_freq_filter(_min_df)
            result = finder.score_ngrams(self.measures.raw_freq)
            result = self._convert_results_horizontally(result)
            #result = finder.score_ngrams(self.measures.likelihood_ratio)
        except Exception, e:
            print ('exception : ', e)            
            raise e

        return result


if __name__=="__main__":
    from keyword_extraction import keyword_extraction
    from konlpy.utils import pprint

    keywords_ext = keyword_extraction()
    collocation_ext = collocation_extraction()

    keywords_ext.document_frequency = (2, 0.9)

    f = open("../data/news_data/news0.txt", "r")
    text = f.read()
    #text = unicode(text)
    f.close()
    keywords = keywords_ext.extraction(text)
    print('\n--------- keywords    -----------')
    pprint(keywords)
    print('\n--------- read_tokens -----------')
    pprint(keywords_ext.read_tokens)

    col = collocation_ext.extraction(keywords_ext.read_tokens, 2)
    print('\n--------- collocation -----------')
    pprint(col)
