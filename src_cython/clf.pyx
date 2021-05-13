# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube 2017
        Writer : Jin Kak, Jung
        Revision History : 
        First released on March, 31, 2017
"""

from sklearn.model_selection import train_test_split
from sklearn import svm
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import label_binarize
from sklearn.multiclass import OneVsRestClassifier
from sklearn.metrics import precision_recall_curve, average_precision_score
from tagger import tagger
import numpy as np
import pandas as pd
from konlpy.tag import Mecab

class text_classification(object):
    def __init__(self):
        self.tagger = Mecab()

    def __del__(self):
        del self.tagger

    def _read_data(self, _filename):
        try:
            with open(_filename, 'r') as f:
                for line in f.read().splitlines():
                    yield line.split('\t')
        except IOError as e:
            print("error ", e)
            raise e

    def _read_meta(self):
        try:
            self.meta_df = pd.read_csv("./clf.meta", names=['clfname', 'value'], sep='\t', header=0)
        except Exception, e:
            raise e

        return self.meta_df.ix[:,1].values.tolist()

    def _tokenizer(self, _docs):
        docs_tokens = ['/'.join(tagged_word) for tagged_word in self.tagger.pos(_docs)]
        return docs_tokens

    def _check_validation(self, _clf_list, _target):
        for v in set(_target):
            if int(v) not in _clf_list:
                return False

        return True

    def training_dataset(self, _filename):
        ldata = []
        ltarget = []
        try:
            clf_list = self._read_meta()
            self.meta_df = self.meta_df.set_index('value')
        except Exception, e:
            raise e

        try:
            for data in self._read_data(_filename):
                ldata.append(data[0])
                ltarget.append(int(data[1]))
        except Exception, e:
            raise e

        if self._check_validation(clf_list, ltarget) == False:
            raise ValueError('Data file/Meta file validation check failed')

        print 'Validation success'

        try:
            self.vectorizer = TfidfVectorizer(tokenizer=self._tokenizer, analyzer='word')
            X = self.vectorizer.fit_transform(ldata) # X=> TFIDF weight by term
            y = ltarget

            # Binarize the output
            y = label_binarize(y, classes=list(set(y)))
            n_classes = y.shape[1]

            random_state = np.random.RandomState(0)
            # Add noisy features
            # from scipy.sparse import hstack
            # from scipy import sparse
            # n_samples, n_features = X.shape
            # X = hstack((X, sparse.csr_matrix(random_state.randn(n_samples, 10 * n_features))))
            X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=.2, 
                    random_state = random_state)

            self.classifier = OneVsRestClassifier(svm.SVC(kernel='linear', C=2, probability=True,
                random_state=random_state))
            y_score = self.classifier.fit(X_train, y_train).decision_function(X_test)
            # Re-train all data
            self.classifier.fit(X, y)

            # Compute Precision-Recall rate
            precision = dict()
            recall = dict()
            avg_precision = dict()
            for i in range(n_classes):
                precision[i], recall[i], _ = precision_recall_curve(y_test[:, i], y_score[:, i])
                avg_precision[i] = average_precision_score(y_test[:, i], y_score[:, i])
                print('--------------- class %d average precision ---------------' % i)
                #print('precision: ', precision, 'recall: ', recall)
                print('precision: ', avg_precision[i]) 

            precision["avg"], recall["avg"], _ = precision_recall_curve(y_test.ravel(), y_score.ravel())
            avg_precision["micro"] = average_precision_score(y_test, y_score, average="micro")
            print('--------------- micro average precision ---------------')
            print('precision: ', avg_precision["micro"]) 

        except Exception, e:
            print("exception : %s" % e.args[0])
            raise e

        return precision, recall, avg_precision

    """
        parameters : 
            _sents : list[string], sentence list for testing, not tokenized list

        returns : 
            list : result list of prediction
                    [
                        sentence : string, 
                        result of classification : string(binary classification) 
                                                 or array of numpy(multiclass classification)
                        probability : list[float, ...]
                    ]
    """
    def prediction(self, _sents):
        if isinstance(_sents, list) == False:
            raise TypeError("_sents must be list type")

        if len(_sents) == 0:
            raise ValueError("There is no data to be tested")

        try:
            test_vectors = self.vectorizer.transform(_sents)
            predictions = self.classifier.predict(test_vectors)
            prediction_probs = self.classifier.predict_proba(test_vectors)

            prediction_result = []

            for idx, sent in enumerate(_sents):
                if len(predictions[idx]) > 1:
                    y_predicted = [idx_ for idx_, value in enumerate(predictions[idx]) if value == 1]
                    if len(y_predicted) > 0:
                        y_predicted = y_predicted[0]
                else:
                    y_predicted = predictions[idx]

                if isinstance(y_predicted, list) == True:
                    if len(y_predicted) == 0:
                        y_predicted = -1

                y_predicted_idx = y_predicted
                if y_predicted > -1:
                    y_predicted = self.meta_df.index[y_predicted]

                y_pred_info = {}
                y_pred_info["code"] = y_predicted
                y_pred_info["prob_idx"] = y_predicted_idx
                if y_predicted > -1:
                    y_pred_info["name"] = self.meta_df.loc[[y_predicted]].iloc[:,0].values[0]
                else:
                    y_pred_info["name"] = "Not classified"
                #y_predicted = y_predicted + "/" + self.meta_df.loc[[y_predicted]].iloc[:,0].values[0]

                #yield sent, y_predicted, prediction_probs[idx].tolist()
                #prediction_result.append([sent, y_predicted, prediction_probs[idx].tolist()])
                prediction_result.append([sent, y_pred_info, prediction_probs[idx].tolist()])

            return prediction_result

        except Exception, e:
            raise e

