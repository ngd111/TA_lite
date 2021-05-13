import collections
from nltk.metrics.scores import precision, recall, f_measure
from nltk.classify import NaiveBayesClassifier
from nltk.corpus import movie_reviews

def word_feats(words):
    return dict([(word, True) for word in words])

negids = movie_reviews.fileids('neg')
posids = movie_reviews.fileids('pos')

negfeats = [(word_feats(movie_reviews.words(fileids=[f])), 'neg') for f in negids]
posfeats = [(word_feats(movie_reviews.words(fileids=[f])), 'pos') for f in posids]

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


print 'pos precision:', precision(refsets['pos'], testsets['pos'])
print '=> Low precision(pos class), 35% false positives'
print 'pos recall:', recall(refsets['pos'], testsets['pos'])
print '=> High sensitive(pos class), 2% false negatives'
print 'pos F-measure:', f_measure(refsets['pos'], testsets['pos'])
print '=> useless in this case, presicion and recall are gives us a better insight'
print 'neg precision:', precision(refsets['neg'], testsets['neg'])
print '=> 96% precision(neg class), 4% false positives'
print 'neg recall:', recall(refsets['neg'], testsets['neg'])
print '=> Low recall(neg class), 52% false negatives'
print 'neg F-measure:', f_measure(refsets['neg'], testsets['neg'])

# One possible explanation for the above results is that people use normally positives words in
# negative reviews, but the word is preceded by “not” (or some other negative word), such as “not
# great”. And since the classifier uses the bag of words model, which assumes every word is
# independent, it cannot learn that “not great” is a negative. If this is the case, then these
# metrics should improve if we also train on multiple words, a topic I’ll explore in a future
# article.

# Another possibility is the abundance of naturally neutral words, the kind of words that are devoid
# of sentiment. But the classifier treats all words the same, and has to assign each word to either
# pos or neg. So maybe otherwise neutral or meaningless words are being placed in the pos class
# because the classifier doesn’t know what else to do. If this is the case, then the metrics should
# improve if we eliminate the neutral or meaningless words from the featuresets, and only classify
# using sentiment rich words. This is usually done using the concept of information gain, aka mutual
# information, to improve feature selection, which I’ll also explore in a future article.
