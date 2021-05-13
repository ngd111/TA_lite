#! /usr/bin/python
#-*- encoding:utf-8 -*-
from clf import text_classification
from utils import utils
from StringIO import StringIO
from konlpy.utils import pprint
import pandas as pd

clf = text_classification()
utils = utils()

print('\n--------- Training dateset -----------------')
prec, recall, avg_prec = clf.training_dataset("./traindata.txt")
print('\n--------- Training report ------------------')
for idx in range(len(prec)-1):
    print('\t class %d ' % idx)
    msg = "precision : \n{0}\nrecall : \n{1}\naverage precision : \n{2}".format(prec[idx], recall[idx], avg_prec[idx])
    print(msg)
print('\n--------- Training done  -------------------')

def _read_file_contents(_filename):
    str_buffer = ""
    with open(_filename, "r") as f:
        str_buffer = f.read()

    str_buffer = utils.convert_encoding(str_buffer)
    str_buffer = StringIO(str_buffer)
    df = pd.read_csv(str_buffer, sep='\||\t', header=None, engine='python')
    df = df.set_index(df.columns[0])

    sents_full = df.iloc[:, 2].tolist()
    return sents_full

sents_full = _read_file_contents('/home/winddori/dev/TA_lite/data/msens/744920160801135717')
print('\n--------- Testing dateset -----------------------------------------')
clf_result = clf.prediction(sents_full)
print('\n--------- Testing result  -----------------------------------------')
for idx, cr in enumerate(clf_result):
    if cr[1]['code'] != 99:
        print('%d => %s' %(idx, cr[0]))
        if cr[1]['code'] == 2:
            print('\tresult : 부정')
        else:
            print('\tresult : 긍정')
        msg = "\tprobability => {0}".format(cr[2])
        print(msg)
print('\n--------- End of testing result -----------------------------------')

