# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube 2017
    Writer : Jin Kak, Jung
    Revision History :
        First released on March, 31, 2017
"""

#from mots_vides import stop_words
#from string import punctuation
#from nltk.corpus import  stopwords as nltk_stopwords
from konlpy.utils import pprint
#from konlpy.tag import Hannanum
from konlpy.tag import Mecab
from utils import utils
#from tagger_utils cimport tagger_utils
#import tester2
import tagger_utils

import cython
import weakref


#cdef class tagger:
class tagger(object):

    #tag_filter = ['NC', 'NQ', 'NB', 'NN', 'NP', 'PV', 'F']
    #tag_filter = ['NNG','NNP','NNB','NNBC','NR','NP','VV','SL','SN']
    #remove NNBC, NR
    tag_filter = ['NNG','NNP','VV','SL','SN']
    #cdef object tagger
    #cdef object utils
    #cdef object stop_words_lang
    #cdef list tokens
    #cdef list stop_words_list
    #cdef dict compound_dict
    #cdef int use_tag_filter
    #cdef int use_stopwords
    #cdef tagger_utils tutils

    def __init__(self, _stopwords = [], _use_tag_filter = False, _use_stopwords = False):
        """
        Initialize the class
         - Set stopwords
         - Make punctuation to Mecab pos tagger format => Depricated
        """
        if isinstance(_stopwords, list) == False:
            raise TypeError('_stopwords parameter type is not list')

        if isinstance(_use_tag_filter, bool) == False:
            raise TypeError('_use_tag_filter parameter type is not bool')

        if isinstance(_use_stopwords, bool) == False:
            raise TypeError('_use_stopwords parameter type is not bool')

        ####### Instance option flags ########
        self.tagger_option = property(fget=weakref.ref(self.get_tagger_option), \
                fset=weakref.ref(self.set_tagger_option))
        self.tagger_option = (_use_tag_filter, _use_stopwords)

        self.stop_words_list = _stopwords
        #print("class tagger __init__")
        self.tagger = Mecab()
        self.utils = utils()
        
        #self.tutils = tagger_utils()
        self.stop_words_lang = self.utils.enum('KO','EN')
        self.tokens = []
        self.compound_dict = {}

    def __enter__(self):
        #print ('tagger __enter__')

        #self.korean_stop_words = stop_words('ko')
        #self.english_stop_words = stop_words('en')
        #self._stopwords = set([word for word in korean_stop_words] + list(punctuation) +
        #        nltk_stopwords.words(u'english'))
        pass

    def __exit__(self, type, value, traceback):
        self._release_resource()
        #print ('tagger __exit__')

    def __del__(self):
        self._release_resource()
        #print ('tagger __del__')

    def _release_resource(self):
        if self.stop_words_lang != None:
            del self.stop_words_lang
            self.stop_words_lang = None
        if self.tokens != None:
            del self.tokens
            self.tokens = None
        if self.stop_words_list != None:
            del self.stop_words_list
            self.stop_words_list = None
        if self.compound_dict != None:
            del self.compound_dict
            self.compound_dict = None
        if self.tagger != None:
            del self.tagger
            self.tagger = None
        if self.utils != None:
            del self.utils
            self.utils = None

#    @property
#    def tagger_option(self):
    def get_tagger_option(self):
        return (self.use_tag_filter, self.use_stopwords)

#    @tagger_option.setter
#    def tagger_option(self, _value):
    def set_tagger_option(self, _value):
        self.use_tag_filter = _value[0]
        self.use_stopwords = _value[1]

    def set_compound_dictionary(self, _dic):
        self.compound_dict = _dic
    
    @property
    #def get_tokens(self):
    def p_tokens(self):
        try:
            return self.tokens
        except AttributeError as e:
            raise AttributeError(e.args[0] + ' Run tokenizer method first')

    def tokenizer(self, _docs):
        docs_tokens = []
        (_use_tag_filter, _use_stop_words) = self.tagger_option

        docs_tokens = ['/'.join(tagged_word) for tagged_word in self.tagger.pos(_docs)]
        # convert unicode to utf-8
        #docs_tokens = [t.decode().encode('utf-8') for t in docs_tokens]

        # Apply compound dictionary
        if (len(self.compound_dict) > 0):
            ## 1. tagger class??? python class????????? ???????????? function entry point??? ?????? ??? ?????? 
            ## interface????????? ??? function??? tagger_utils??? ????????? case??? ??? ????????? ????????????
            ## ??????????????? ?????? ?????? ??? ??????.
            try:
                docs_tokens = tagger_utils.apply_compound_dictionary(docs_tokens, self.compound_dict)
            except Exception, e:
                msg = "exception : compound dictionary processing => {0}".format(e)
            ## 2. tagger class??? cdef class ??? ??????????????? ????????? function entry point??? ?????? ??? ??????.
            #docs_tokens = self.tutils._apply_compound_dictionary(docs_tokens, self.compound_dict)
            ## 3. tagger class??? python class??? ???????????? function entry point?????? ??? ??????
            ## tagger_interface??? ?????? ???????????? ??????
            #docs_tokens = tagger_interface.tagger_utils_apply_com(docs_tokens, self.compound_dict)
            
        if _use_tag_filter == True:
            docs_tokens = [t for t in docs_tokens if t.split('/')[1] in tagger.tag_filter]
            #docs_tokens = ['/'.join(tagged_word) for tagged_word in self.tagger.pos(_docs)
            #        if tagged_word[1] in tagger.tag_filter]

        if (_use_stop_words == True and len(self.stop_words_list) > 0):
            filtered_tokens = [token for token in docs_tokens if token not in self.stop_words_list]
            self.tokens = self.tokens + filtered_tokens
            return filtered_tokens
        else:
            self.tokens = self.tokens + docs_tokens
            return docs_tokens

    # _text : multi-document lists or single document text(string)
    # _docs list type option is reserved for future use (To support topic modeling)
    #def tag_text(self, _docs, _tag_filter=True, _stopwords_lang=stop_words_lang.KO):
    def tag_text(self, _docs):
        if type(_docs) not in (list, str):
            raise TypeError

        self.tokens = []

        if type(_docs) == list:
            tokens = [self.tokenizer(doc) for doc in _docs]
            #tokens = [self.tokenizer(unicode(doc)) for doc in _docs]
        else:
            tokens = self.tokenizer(_docs)
            #tokens = self.tokenizer(unicode(_docs))

        return tokens


if __name__=='__main__':
    pos_tagger = tagger()

    # Multi-documents tagging
    #docs = []
    #for i in range(10):
    #    filename = "../data/news_data/news" + str(i) + ".txt"
    #    f = open(filename, "r")
    #    text = f.read()
    #    docs.append(text)

    # Single-document tagging
    #f = open("../data/news_data/target_news.txt","r")
    f = open("../data/testcall.txt","r")
    text = f.read()
    f.close()
    #print(text)

    print("\n================================================================")
    print("============= Tagging ==========================================\n")
    with pos_tagger:
        pos_tagger.tagger_option = (False, False)
        tokens = pos_tagger.tag_text(text)
        #tokens = pos_tagger.tag_text(docs)
        pprint(tokens)

    #print('~~~ keywords ~~~~~')
    #pprint(pos_tagger.read_tokens)



