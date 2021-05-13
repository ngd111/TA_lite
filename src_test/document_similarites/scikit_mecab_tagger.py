#! /usr/bin/python
# -*- coding: utf-8 -*-
from konlpy.tag import Mecab
from konlpy.utils import pprint
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import linear_kernel
import sys


if len(sys.argv) == 1:
    print "분석할 문장을 입력해주세요"
    exit(1)

tagger = Mecab()

tag_filter = ['NNG','NNP','VV','SL','SN']

def tokenizer(doc):
    docs_tokens = ['/'.join(t) for t in tagger.pos(doc)]
    return [t for t in docs_tokens if t.split('/')[1] in tag_filter]
    #return ['/'.join(t) for t in tagger.pos(doc)]

print '------------------------------------------------------------------------------------'
print '분석대상 문장 ; ', sys.argv[1]
print '------------------------------------------------------------------------------------'

print '-------------------- Training dataset ----------------------------------------------'
documents = [u"배송지연으로 인한 환불정책을 알고 싶습니다. 되기는 되는 것인가요",
        u"배송이 완료되었습니다. 고객님",
        u"해당 상품 두가지는 일괄 배송이 됩니다",
        u"고객님 제가 알아보고 다시 연락드리겠습니다",
        u"상담원 홍길동이었습니다",
        u"내일까지 배송될 예정입니다. 조금만 기다려주십시오",
        u"상품 파손시 환불이 불가능합니다",
        u"상품 수거 후 환불완료가 될 것입니다. 내일 방문하는 택배원에게 상품을 보내주세요",
        u"지금 집에 없는데 경비실에 맡겨주세요",
        u"아직도 배송이 안되었는데 언제 배송되나요 연락도 없구요",
        u"고객님이 주문하신 상품이 품절이 되었습니다. 결제를 취소처리하려 합니다",
        u"고객님 품절된 상품 대신 다른 상품으로 대체 발송하려 하는데 동의하시나요",
        u"배송기사가 상자를 던져서 상품이 파손되었습니다. 환불을 해주시던지 다른 상품을 보내주세요",
        u"배송 중 파손이 된 것 같은데요. 파손 보상책이 준비되어 있나요"
        ]

pprint(documents)

#stoplist = [u"",]

vectorizer = TfidfVectorizer(min_df=2, analyzer='word', tokenizer=tokenizer)
tfidf = vectorizer.fit_transform(documents)

print '\n'
print '-------------------- Keywords -------------------------------------------------------'
pprint(vectorizer.vocabulary_)
print '-------------------- End of keywords ------------------------------------------------'
print '\n'

new_document = []
#new_document.append(u"배송 중 상자가 파손되었어요")
new_document.append(sys.argv[1])
tfidf_new = vectorizer.transform(new_document)

cosine_similarities = linear_kernel(tfidf_new, tfidf).flatten()

# find top 5 documents
related_docs_indices = cosine_similarities.argsort()[:-6:-1]
cosine_similarities[related_docs_indices]

# query top 5 documents original sentences(except zero value similarity docs)
print '-------------------- Top 5 sentences ------------------------------------------------'
print '  유사도(%)\tSentence'
print '------------- -----------------------------------------------------------------------'
for idx in related_docs_indices:
    if cosine_similarities[idx] > 0:
        print cosine_similarities[idx] * 100, documents[idx], '\t/index =>', idx
print '-------------------- End of sentences -----------------------------------------------'


