# -*- coding: utf-8 -*-

from konlpy.utils import pprint
from konlpy.tag import Mecab
import nltk

from sklearn.model_selection import train_test_split
from sklearn import svm


class sa:
    def __init__(self):
        self.tagger = Mecab()
        
    def __del__(self):
        del self.tagger
        
    def tokenize(self, doc):
        return ['/'.join(t) for t in self.tagger.pos(doc)]
    
    def read_data(self, filename):
        with open(filename, 'r') as f:
            data = [line.split('\t') for line in f.read().splitlines()]
        return data
     
    def term_exists(self, doc):
        return dict([(word, (word in set(doc))) for word in self.selected_words])

if __name__=='__main__':

    sent_a = sa()

    #train_data = sent_a.read_data('./msens_traindata.txt')
    #test_data  = sent_a.read_data('./msens_testdata.txt')
    train_data = sent_a.read_data('./traindata.txt')
    test_data  = sent_a.read_data('./743420160801100845')

    train_docs = [(sent_a.tokenize(row[0]), row[1]) for row in train_data]
    test_docs  = [sent_a.tokenize(row[0]) for row in test_data]

    tokens = [t for d in train_docs for t in d[0]]

    # data exploration
    text = nltk.text.Text(tokens, name='voc analysis')

    print(len(set(text.tokens)))  # number of unique tokens
    pprint(text.vocab().most_common(10)) # frequency distribution (시간이 소요됨. vocabulary creation time)

    # sentiment classification with term-existence
    # use most common term 1000
    sent_a.selected_words = [f[0] for f in text.vocab().most_common(1000)]

    # training data 전처리에 시간이 소요됨
    train_xy = [(sent_a.term_exists(d), c) for d, c in train_docs]
    # tesing data 실시간 전처리
    test_xy  = [sent_a.term_exists(d) for d in test_docs]

    # training classifier
    # training 시간이 소요됨
    classifier = nltk.classify.NaiveBayesClassifier.train(train_xy)
    #print 'accuracy:', nltk.classify.util.accuracy(classifier, test_xy)
    classifier.show_most_informative_features(10)

    # tesing data(실시간 처리)
    classified_test_xy = classifier.classify_many(test_xy)

    # test document의 긍부정 비율을 수치로 나타낸다.
    for pdist in classifier.prob_classify_many(test_xy):
        #print('%.4f %.4f %.4f' % (pdist.prob('-1'), pdist.prob('0'), pdist.prob('1')))
        print('%.4f %.4f %.4f %.4f' % (pdist.prob('0'), pdist.prob('1'), pdist.prob('2'), pdist.prob('3')))

    # test document 와 result 출력
    for text, result in zip(test_data, classified_test_xy):
        print text[0], result




