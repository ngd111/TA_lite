# -*- coding: utf-8 -*-
from sentimental_classifier_t import sa
import collections
import nltk
from nltk.metrics.scores import precision, recall, f_measure
from nltk.classify import NaiveBayesClassifier

sent_a = sa()

train_data = sent_a.read_data('./traindata_except_01.txt')

train_docs = [(sent_a.tokenize(row[0]), row[1]) for row in train_data]

tokens = [t for d in train_docs for t in d[0]]
# data exploration
text = nltk.text.Text(tokens, name='voc analysis')
sent_a.selected_words = [f[0] for f in text.vocab().most_common(1000)]
train_xy = [(sent_a.term_exists(d), c) for d, c in train_docs]

# 2(neg)와 3(pos) 으로 분류를 나눈다.
negfeats = []
posfeats = []

for d in train_xy:
    if d[1] == '2':
        negfeats.append((d[0], d[1]))
    elif d[1] == '3':
        posfeats.append((d[0], d[1]))
        
negcutoff = len(negfeats)*3/4
poscutoff = len(posfeats)*3/4

trainfeats = negfeats[:negcutoff] + posfeats[:poscutoff]
testfeats = negfeats[negcutoff:] + posfeats[poscutoff:]
print 'train on %d instances, test on %d instances' % (len(trainfeats), len(testfeats))

classifier = NaiveBayesClassifier.train(trainfeats)
refsets = collections.defaultdict(set)
testsets = collections.defaultdict(set)

for i, (feats, label) in enumerate(testfeats):
    refsets[label].add(i)
    observed = classifier.classify(feats)
    testsets[observed].add(i)

print 'pos precision:', precision(refsets['3'], testsets['3'])
print 'pos recall:', recall(refsets['3'], testsets['3'])
print 'pos F-measure:', f_measure(refsets['3'], testsets['3'])
print 'neg precision:', precision(refsets['2'], testsets['2'])
print 'neg recall:', recall(refsets['2'], testsets['2'])
print 'neg F-measure:', f_measure(refsets['2'], testsets['2'])


#불만 : 2 (recall 이 67%로 33% false positive가 있다)
#문의 : 3
