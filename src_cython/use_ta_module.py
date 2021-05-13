from os import listdir
from os.path import isfile, join
from ta_proc import TA_proc
from time import time


#data_path = '/home/winddori/dev/TA_lite/data/news_data/'
#filenames = [data_path + f for f in listdir('../data/news_data/') if
#        isfile(join('../data/news_data/',f)) if f[0:4] == 'news']
data_path = '/home/winddori/dev/TA_lite/data/msens/'
filenames = [data_path + f for f in listdir('../data/msens/') if
        isfile(join('../data/msens/',f)) ]
#filenames = [data_path + 'testcall.txt']

ta = TA_proc()

def run():
    t0 = time()
    ta.do_processing(filenames)
    print("done in %0.5fs." % (time() - t0))

##@profile => python -m memory_profiler use_ta_module.py
#def run():
#    while(True!=False):
#        t0 = time()
#        ta.do_TA_processing(filenames)
#        print("done in %0.5fs." % (time() - t0))

run()


