# -*- coding: utf-8 -*-
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import NMF
from konlpy.tag import Hannanum
from konlpy.utils import pprint
# TF-IDF로서 처리될 때 
# 한 콜에 대한 분석시에만 sentence 분리가 의미가 있다.
# 여러 콜. 즉, 1000콜 정도의 데이터 분석이면 콜 전체가 하나의 sentence로서 처리되면 된다.
from nltk.tokenize import sent_tokenize

from time import time
                                          
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
    text = unicode(text)
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

def print_top_words(model, feature_names, n_top_words):
    for topic_idx, topic in enumerate(model.components_):
        print("Topic #%d:" % topic_idx)
        print(" ".join([feature_names[i]
            for i in topic.argsort()[:-n_top_words - 1:-1]]))


# Fit the NMF model
print ("Fitting the NMF model with TF-IDF features")
t0 = time()
nmf = NMF(n_components=n_topics, random_state=1).fit(tfidf)
print("done in %0.3fs." % (time() - t0))

print("Topics in NMF model:")
tfidf_features_names = vectorizer.get_feature_names()
print_top_words(nmf, tfidf_features_names, n_top_words)
