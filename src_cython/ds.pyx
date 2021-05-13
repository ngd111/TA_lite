# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube 2017
        Writer : Jin Kak, Jung
        Revision History :
        First released on Apr, 30, 2017
"""
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import linear_kernel
from konlpy.utils import pprint
import cython

from tagger import tagger
from utils import utils, log
import weakref

class document_similarity(object):
    def __init__(self):
        self.utils = utils()
        self.tag = tagger()
        self.document_frequency = property(fget=weakref.ref(self.get_document_frequency), \
                fset=weakref.ref(self.set_document_frequency))
        print("ds object initialized")

    def __del__(self):
        print("ds object deinitialized")
        del self.tag
        del self.utils

    def _read_data(self, _filename):
        try:
            with open(_filename, 'r') as f:
                for line in f.read().splitlines():
                    yield line
        except IOError as e:
            raise e

    def get_document_frequency(self):
        try:
            return (self.min_df, self.max_df)
        except AttributeError as e:
            print(e)

    def set_document_frequency(self, _min_value, _max_value):
        self.min_df = _min_value
        self.max_df = _max_value

    """
        parameter : tuple that contains tuples ((id int, text string), (), ....)
    """
    def vectorizing(self, _resultset):
        self.documents = []
        self.ids = []

        try:
            (_min_df, _max_df) = self.document_frequency
        except TypeError as e:
            raise TypeError('Set document frequency factor first' + e.args[0])

        if isinstance(_resultset, tuple) == False:
            raise TypeError("_resultset is not tuple type. check parameter")

        for result in _resultset:
            self.ids.append(result[0])
            self.documents.append(self.utils.convert_encoding(result[1]))

        #try:
        #    for data in self._read_data(_filename):
        #        self.documents.append(data)
        #except Exception, e:
        #    raise e


        self.vectorizer = TfidfVectorizer(tokenizer=self.tag.tokenizer, \
                    analyzer='word', min_df=_min_df, max_df=_max_df)
        self.tfidf = self.vectorizer.fit_transform(self.documents)

    def get_similar_sentences(self, _sentence, _top = 5, _threshold = 0.5):
        new_document = [_sentence]
        tfidf = self.vectorizer.transform(new_document)
        cos_similarities = linear_kernel(tfidf, self.tfidf).flatten()

        # find top n sentences
        related_sents_indice = cos_similarities.argsort()[:-_top-1:-1]
        #cos_similarities[related_sents_indice]

        # query top n original sentences(exclude zero value similarity sentences)
        for idx in related_sents_indice:
            if cos_similarities[idx] > _threshold:
                yield self.ids[idx], cos_similarities[idx], self.documents[idx]

