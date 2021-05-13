# -*- coding: utf-8 -*-
from gensim import corpora, models
import gensim
from konlpy.tag import Hannanum
from konlpy.utils import pprint
# TF-IDF로서 처리될 때 
# 한 콜에 대한 분석시에만 sentence 분리가 의미가 있다.
# 여러 콜. 즉, 1000콜 정도의 데이터 분석이면 콜 전체가 하나의 sentence로서 처리되면 된다.
from nltk.tokenize import sent_tokenize

from time import time
#import sys

#reload(sys)
#sys.setdefaultencoding('utf-8')
                                          
tagger = Hannanum()

tag_filter = ['NC', 'NQ', 'NB', 'NN', 'NP', 'PV', 'F']

# tagging and tokenizer
def _tokenizer(text):
    tokens = ['/'.join(tagged_word) for tagged_word in tagger.pos(text, ntags=22)
              if tagged_word[1] in tag_filter]      
    return tokens

docs = [] # document 전체를 담을 변수

for i in range(10):
    filename = "../data/news_data/news" + str(i) + ".txt"
    f = open(filename, "r")
    text = f.read()
    #text = unicode(text)
    docs.append(text)
    f.close()

doc_tokens = [_tokenizer(doc) for doc in docs]


print("************************** Start Topic extraction ******************************\n")
n_topics = 3
n_top_words = 10

dic = corpora.Dictionary(doc_tokens)
dic.save('news.dic') # for future use

tf = [dic.doc2bow(tokens) for tokens in doc_tokens]
tfidf_model = models.TfidfModel(tf)
tfidf = tfidf_model[tf]
corpora.MmCorpus.serialize('news.mm', tfidf) # save corpus to file for future use

import numpy as np
#np.random.seed(3)    # optional
lda = models.LdaModel(tfidf, id2word=dic, num_topics=n_topics)
pprint(lda.print_topics(num_topics=n_topics, num_words=n_top_words))


