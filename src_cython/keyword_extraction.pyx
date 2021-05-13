# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube 2017
        Writer : Jin Kak, Jung
        Revision History :
        First released on March, 31, 2017
"""
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from konlpy.utils import pprint
import cython

from operator import itemgetter

# TF-IDF로서 처리될 때 
# 한 콜에 대한 분석시에만 sentence 분리가 의미가 있다.
# 여러 콜. 즉, 1000콜 정도의 데이터 분석이면 콜 전체가 하나의 sentence로서 처리되면 된다.
from time import time
from tagger import tagger
from utils import utils, log

#cdef class keyword_extraction:
class keyword_extraction(object):
    #cdef object tagger
    #cdef object utils
    #cdef object vectorizer_type
    #cdef object min_df, max_df

    #def __init__(self, _logger_object):
    def __init__(self):
        #if isinstance(_logger_object, log) == False:
        #    raise TypeError('_logger_object is not utils.log object')

        #self.logger = _logger_object
        self.utils = utils()
        self.vectorizer_type = self.utils.enum('TFIDF','COUNT')
        self.tokens = {}
        self.vocabulary = {}
        self.document_frequency = property(fget=self.get_document_frequency, 
                fset=self.set_document_frequency)
        print("keywords object initialized")

    def __del__(self):
        del self.utils
        del self.vectorizer_type
        del self.tokens
        del self.vocabulary
        print("keywords object deinitialized")

#    --- for cdef class 
#    property document_frequency:
#        def __get__(self):
#            try:
#                return (self.min_df, self.max_df)
#            except AttributeError as e:
#                print('exception:', e.args[0])
#                return
#
#        def __set__(self, _value):
#            self.min_df = _value[0]
#            self.max_df = _value[1]

#    @property
#    def document_frequency(self):
    def get_document_frequency(self):
        try:
            return (self.min_df, self.max_df)
        except AttributeError as e:
            print(e)
            return

#    @document_frequency.setter
#    def document_frequency(self, _min_value, _max_value):
    def set_document_frequency(self, _min_value, _max_value):
        self.min_df = _min_value
        self.max_df = _max_value

#    property read_tokens:
#        def __get__(self):
#            return self.tagger.read_tokens

    def read_tokens(self, _thread_id=0):
        return self.tokens.get(_thread_id)
        #return self.tagger.read_tokens

    def read_vocabulary(self, _thread_id=0):
        return self.vocabulary.get(_thread_id)

    """
        parameters :
            _sents : list[string], sentence tokenize list
            _compound_words_dictionary : dict{(string, string, ...):string}, 
                     support 2 or 3 gram currently
            _thread_id int : thread identifier(to support multi-threaded runtime environment)
            _vectorizer_type enum : TFIDF or COUNT
                TFIDF(default) : use TFIDF vectorizer
                COUNT : use Count vectorizer

        returns : 
            keywords sorted(descending) by weight : list[tuple(keyword, weight)]
                ex) [(의무/NC, 7.1520232232305707), (신청/NC, 6.4510232232305000)]
    """
    #def extraction(self, _text, _compound_words_dictionary=None, _thread_id=0, _vectorizer_type=None):
    def extraction(self, _sents, _compound_words_dictionary=None, _stop_words_list=None,
            _thread_id=0, _vectorizer_type=None):
        _vectorizer_type = _vectorizer_type or self.vectorizer_type.TFIDF

        try:
            if _stop_words_list == None:
                tag = tagger(_use_tag_filter = True, _use_stopwords = True)
            else:
                tag = tagger(_stop_words_list, _use_tag_filter = True, _use_stopwords = True)
        except Exception, e:
            print("exception : %s" % e.args[0])
            raise e 

        with tag:

            if (_compound_words_dictionary != None):
                tag.set_compound_dictionary(_compound_words_dictionary)

            try:
                (_min_df, _max_df) = self.document_frequency
            except TypeError as e:
                raise TypeError('Set document frequency factor first' + e.args[0])
            
            self.tokens[_thread_id] = []

            #sents = sent_tokenize(_text)
            
            try:
                if _vectorizer_type == self.vectorizer_type.TFIDF:
                    vectorizer = TfidfVectorizer(tokenizer=tag.tokenizer, analyzer='word', 
                            min_df=_min_df, max_df=_max_df)
                    #tfidf = vectorizer.fit_transform(sents)
                    vectorizer.fit_transform(_sents)
                    result_dic = dict(zip(vectorizer.get_feature_names(), vectorizer.idf_))
                    self.vocabulary[_thread_id] = vectorizer.get_feature_names()
                else:
                    vectorizer = CountVectorizer(tokenizer=tag.tokenizer, analyzer='word',
                            min_df=_min_df, max_df=_max_df)
                    X = vectorizer.fit_transform(_sents)
                    X_arr = X.toarray()
                    result_dic = dict(zip(vectorizer.get_feature_names(), X_arr.sum(axis=0).tolist()))
                    self.vocabulary[_thread_id] = vectorizer.get_feature_names()

                    del X_arr
                    del X
                            
                sorted_term_weight = sorted(result_dic.items(), key=lambda x: -x[1])            
                del result_dic
                del vectorizer
                # Jin Kak, Jung write a comment below
                # => When you make cdef type class, should remember the cythons' limitation.
                # ==> cdef class can't support lambda function.
                # To avoid compile error, use the line below instead of the line above 
                # compile error => 'closures inside cpdef functions not yet supported'
                # Use next approach, in case of cdef or cpdef function declaration
                #
                # sorted_term_weight = sorted(result_dic.items(), key=itemgetter(1), reverse=True)

            except ValueError as e:
                print("exception : %s" % e.args[0])
                raise e
            except AttributeError as e:
                print("exception : %s" % e.args[0])
                raise e

            self.tokens[_thread_id] = tag.p_tokens

            del _sents
	        
        del tag

        return sorted_term_weight

if __name__=="__main__":
    extraction_cls = keyword_extraction() 

    extraction_cls.document_frequency = (2, 0.95)
    #print(extraction_cls.document_frequency)
    #for i in range(10):
    for i in range(1):
        #file = "../data/news_data/news" + str(i) + ".txt"
        file = "../data/news_data/ori_testcall.txt"
        f = open(file, "r")
        text = f.read()
        #text = unicode(text).replace('\n','. ')
        text = text.replace('\n','. ')
        f.close()
        # read stopwords
        
        print("\n================================================================")
        print("============= Extract keywords ==================================\n")
        print(extraction_cls.document_frequency)
        #keywords = extraction_cls.extraction(text, extraction_cls.vectorizer_type.COUNT)
        keywords = extraction_cls.extraction(text)
        if keywords != None:
            pprint(keywords)
        #pprint(text)
        print(" ~~~~~~~~~~~~~~~~~~~~~~~~tokens~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")
        #pprint(extraction_cls.read_tokens)
        print(" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")


