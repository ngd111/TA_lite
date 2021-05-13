# -*- coding: utf-8 -*-
##  sklearn의 Tfidf를 변환해서 gensim의 LDA모델에 넣었으나 vocabulary(weight로 sorting후 생성) 문제가 생겨 실패함
## Tfidf term weight과 sync가 안 맞아서 실패함
from sklearn.feature_extraction.text import TfidfVectorizer
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

sents = [] # document 전체를 담을 변수

for i in range(10):
    filename = "../data/news_data/news" + str(i) + ".txt"
    f = open(filename, "r")
    text = f.read()
    #text = unicode(text)
    sents.append(text)
    f.close()

vectorizer = TfidfVectorizer(tokenizer=_tokenizer, analyzer='word', min_df=2, max_df=0.95)

tfidf = vectorizer.fit_transform(sents)

result_dic = dict(zip(vectorizer.get_feature_names(), vectorizer.idf_))

sorted_term_weight = sorted(result_dic.items(), key=lambda x:-x[1])

# sentence별 words의 TF-IDF
print(tfidf)

# 모든 words의 TF-IDF
tfidf.data

# vocabulary
pprint(vectorizer.vocabulary_)

# '글로벌'이 포함된 문서 Index출력
vectorizer.vocabulary_[u'글로벌/NC'] # Voca index 출력 => 43

r = tfidf.nonzero()

# find all indices of key(43)
indexes = [i for i, x in enumerate(r[1]) if x == 43] # Keywords 중 Voca가 출현한 index 찾기
# Result => [51, 438]

# term 이 키워드의 51와 438 번째에 존재하므로 r[0]를 이용해 sentence ID를 찾는다.
r[0][indexes]
# Result => array([0, 8])

# '글로벌'이 포함된 sentence 조회
for idx in r[0][indexes]:
    print("Doc ID : %d\n" % idx)
    pprint(sents[idx])
    print("==================================================================================================\n")


print("************************** Start Topic extraction ******************************\n")
n_topics = 3
n_top_words = 10

# Fit the LDA model
print ("Fitting the LDA model with TF-IDF features")
t0 = time()
#nmf = NMF(n_components=n_topics, random_state=1).fit(tfidf)
corpus = gensim.matutils.Sparse2Corpus(tfidf)
voca_gensim = {}
for k, v in vectorizer.vocabulary_.items():
        voca_gensim[v] = k

lda = gensim.models.LdaModel(corpus, n_topics, id2word = voca_gensim)
lda.print_topics(n_topics, n_top_words)
print("done in %0.3fs." % (time() - t0))
