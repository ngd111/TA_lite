# -*- coding: utf-8 -*-

from konlpy.utils import pprint
from konlpy.tag import Mecab
import nltk


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
            data = data[1:]
        return data
     
    def term_exists(self, doc):
        return dict([(word, (word in set(doc))) for word in self.selected_words])

if __name__=='__main__':

    sent_a = sa()

    train_data = sent_a.read_data('./nsmc-master/ratings_train.txt')
    test_data  = sent_a.read_data('./my_movie_ratings_test.txt')

    train_data = train_data[:15000] 

    train_docs = [(sent_a.tokenize(row[1]), row[2]) for row in train_data]
    test_docs  = [sent_a.tokenize(row[1]) for row in test_data]

    tokens = [t for d in train_docs for t in d[0]]

    # data exploration
    text = nltk.text.Text(tokens, name='Movie comment analysis')

    print(len(set(text.tokens)))  # number of unique tokens
    pprint(text.vocab().most_common(10)) # frequency distribution (시간이 소요됨. vocabulary creation time)

    # sentiment classification with term-existence
    # use most common term 2000
    sent_a.selected_words = [f[0] for f in text.vocab().most_common(2000)]

    # training data 전처리에 시간이 소요됨
    train_xy = [(sent_a.term_exists(d), c) for d, c in train_docs]
    # tesing data 실시간 전처리
    test_xy  = [sent_a.term_exists(d) for d in test_docs]

    # training classifier
    # training 시간이 소요됨
    classifier = nltk.classify.NaiveBayesClassifier.train(train_xy)
    classifier.show_most_informative_features(10)

    # testing data(실시간 처리)
    classified_test_xy = classifier.classify_many(test_xy)

    # test document의 긍부정 비율을 수치로 나타낸다.
    for pdist in classifier.prob_classify_many(test_xy):
        print('%.4f %.4f' % (pdist.prob('0'), pdist.prob('1')))

    # test document 와 result 출력
    for text, result in zip(test_data, classified_test_xy):
        print text[1], result




