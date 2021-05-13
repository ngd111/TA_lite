# -*- coding: utf-8 -*-
from sklearn.model_selection import train_test_split
from sklearn import svm
from sklearn.metrics import classification_report, precision_recall_curve, average_precision_score
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import label_binarize
from sklearn.multiclass import OneVsRestClassifier
from sentimental_classifier_t import sa
import numpy as np
from itertools import cycle
import matplotlib

import sys

matplotlib.use('Agg')
import matplotlib.pyplot as plt

def read_data_t(filename):
    r_data = []
    f = open(filename, 'r')
    data = [line.split('\t') for line in f.read().splitlines()]
    data = data[1:]
    for d in data:
        r_data.append(d[1:])
    return r_data

train_data_size = 0
if len(sys.argv) == 1:
    train_data_size = 15000
else:
    train_data_size = int(sys.argv[1])

# setup plot details
colors = cycle(['navy', 'turquoise','darkorange','cornflowerblue','teal'])
lw = 2

sent_a = sa()

train_data = sent_a.read_data('./traindata.txt')
test_data = sent_a.read_data('./743420160801100845')
#train_data = read_data_t('./mv_traindata.txt')
#test_data = read_data_t('./mv_testdata.txt')

#train_data = train_data[:20000]
train_data = train_data[:train_data_size]

ltestdata = []
for te in test_data:
    ltestdata.append(te[0])

ldata = []
ltarget = []

for tr in train_data:
    ldata.append(tr[0])
    ltarget.append(int(tr[1]))

vectorizer = TfidfVectorizer(tokenizer=sent_a.tokenize)
tfidf = vectorizer.fit_transform(ldata)
test_vectors = vectorizer.transform(ltestdata)
#result_dic = dict(zip(vectorizer.get_feature_names(), vectorizer.idf_))

#X = tfidf.data
X = tfidf
y = ltarget

# Binarize the output
#y = label_binarize(y, classes=[0,1,2,3])
y = label_binarize(y, classes=list(set(y)))
n_classes = y.shape[1]

# Add noisy features??
#from scipy.sparse import hstack
#from scipy import sparse
#
random_state = np.random.RandomState(0)
#n_samples, n_features = X.shape
##X = np.c_[X, random_state.randn(n_samples, 200 * n_features)]
#X = hstack((X, sparse.csr_matrix(random_state.randn(n_samples, 3 * n_features))))

# Split into training and test
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=.5, random_state=random_state)

# Run classifier
classifier = OneVsRestClassifier(svm.SVC(kernel='linear', probability=True,
    random_state=random_state))
#classifier = OneVsRestClassifier(svm.LinearSVC())
y_score = classifier.fit(X_train, y_train).decision_function(X_test)

predictions = classifier.predict(test_vectors)
### result of prediction of test data
print(predictions)
### probabilites
print(classifier.predict_proba(test_vectors))
### accuracy on the given test data and labels(no labels given)예측치(labels)가 주어져야 score볼 수 있다.
### print(classifier.score(test_vectors, labels)

# result of prediction with test_data
# sententce, prediction result(0~3 or empty value)
for idx, sent in enumerate(ltestdata):
    if len(predictions[idx]) > 1:
        y_predicted = [str(idx_) for idx_, value in enumerate(predictions[idx]) if value == 1]
    else:
        y_predicted = str(predictions[idx])
    print sent, "".join(y_predicted)

# Compute Precision-Recall and plot curve
precision = dict()
recall = dict()
average_precision = dict()
for i in range(n_classes):
    precision[i], recall[i], _ = precision_recall_curve(y_test[:, i], y_score[:, i])
    average_precision[i] = average_precision_score(y_test[:, i], y_score[:, i])

# Compute micro-average ROC curve and ROC area
precision["micro"], recall["micro"], _ = precision_recall_curve(y_test.ravel(), y_score.ravel())
average_precision["micro"] = average_precision_score(y_test, y_score, average="micro")

# Plot Precision-Recall curve
#plt.clf()
#plt.plot(recall[0], precision[0], lw=lw, color='navy', label='Precision-Recall curve')
#plt.xlabel('Recall')
#plt.ylabel('Precision')
#plt.ylim([0.0, 1.05])
#plt.xlim([0.0, 1.0])
#plt.title('Precision-Recall : AUC={0:0.2f}'.format(average_precision[0]))
#plt.legend(loc="lower left")
#plt.savefig("./plot_precision_recall_traindata_1.png")

# Plot precision-Recall curve for each class
plt.clf()
#plt.plot(recall["micro"], precision["micro"], color='gold', lw=lw,
#                label='micro-average Precision-recall curve (area = {0:0.2f})'.format(average_precision["micro"]))
plt.plot(recall["micro"], precision["micro"], color='gold', lw=lw,
                label='micro-average Precision-Sensitivity curve (area = {0:0.2f})'.format(average_precision["micro"]))
#for i, color in zip(range(n_classes), colors):
#    plt.plot(recall[i], precision[i], color=color, lw=lw,
#        label='Precision-recall curve of class {0} (area = {1:0.2f})'.format(i, average_precision[i]))

plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
#plt.xlabel('Recall')
plt.xlabel('Sensitivity')
plt.ylabel('Precision')
#plt.title('Extension of Precision-Recall curve to multi-class')
plt.title('Extension of Precision-Sensitivity curve to sentimental analysis')
plt.legend(loc="lower right")

plt.savefig("./plot_precision_recall_traindata20k_moviereview.png")
