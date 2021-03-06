# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube 2017
        Writer : Jin Kak, Jung
            Revision History :
            First released on March, 31, 2017
"""
import logging

from cython.parallel import parallel, prange

cimport cython
cimport openmp
import gc
import numpy as np
import os

# Import TA internal packages
from collocation_extraction import collocation_extraction
from keyword_extraction import keyword_extraction
from dataproc import mongodb
from clf import text_classification

from konlpy.utils import pprint

import weakref
from utils import log, utils
from proc_base import proc_base

#import jpype

#from libc.stdio cimport printf

#cdef extern from "unistd.h" nogil:
#    unsigned int sleep(unsigned int seconds)

class ta_proc(proc_base):
    #cdef object keywords_ext
    #cdef object collocation_ext

    class custom_exception(Exception):
        pass

    def __init__(self, _num_threads, _log_filename, _parent, \
            _mongodb_host="localhost", _mongodb_port=27017, _mongodb_db = "msens_db"):
        proc_base.__init__(self, _num_threads, _log_filename, _parent, \
                _mongodb_host, _mongodb_port, _mongodb_db)

        self.clf = text_classification()

        self.collocation_ext = collocation_extraction()
        self.keywords_ext = keyword_extraction()
        self.keywords_ext.document_frequency = (2, 0.95)
        self.do_reload_dictionary()                
        self.logger.write_log("info", "TA processing object initialized")
        self.do_training()

    def __del__(self):
        proc_base.__del__(self)
        self.logger.write_log("info", "TA processing object deinitialized")
        del self.collocation_ext
        del self.keywords_ext
        del self.clf

    def do_training(self):
        try:
            prec, recall, avg_prec = self.clf.training_dataset("./traindata.txt")
        except Exception, e:
            msg = "exception occurred while training data set => {0}".format(e)
            self.logger.write_log("error", msg)
            raise e

        self.logger.write_log("info", "================== Training report ==================")
        for idx in range(len(prec)-1):
            self.logger.write_log("info", "\t class %d " % idx)
            msg = "precision : \n{0}\nrecall : \n{1}\naverage precision : \n{2}".format(prec[idx], recall[idx], avg_prec[idx])
            self.logger.write_log("info", msg)

        self.logger.write_log("info", "average precision : \n{0}".format(prec["avg"]))
        self.logger.write_log("info", "average recall    : \n{0}".format(recall["avg"]))
        self.logger.write_log("info", "\t micro average precision : %f" % avg_prec["micro"])
        self.logger.write_log("info", "================== End of report ====================")
        self.logger.write_log("info", "Dataset training completed")
        del prec, recall, avg_prec
        
    def __run_extraction(self, _sentences, _thread_num, _fileid):
        keywords = []
        collocations = []

        try:
            keywords = self.keywords_ext.extraction(
                    _sents = _sentences, _thread_id = _thread_num, 
                    _compound_words_dictionary = self.c_dict,
                    _stop_words_list = self.stop_words_list)
        except Exception, e:
            #msg = "exception occurred while processing keywords extraction => {0}".format(e)
            #self.logger.write_log("error", msg)
            raise e
            #msg = "failed to extract keywords => {0}".format(e)
            #raise custom_exception(msg, -1)

        if keywords == None or len(keywords) == 0:
            return keywords, collocations

        if len(keywords) > 1:
            try:
                # Remove tagged words are not in keyword list
                filtered_tokens = []
                morphs_keywords = [t[0] for t in keywords]
                tagged_tokens = self.keywords_ext.read_tokens(_thread_num)
                for t in tagged_tokens:
                    if t in morphs_keywords:
                        filtered_tokens.append(t)

                collocations = self.collocation_ext.extraction(filtered_tokens)
            except Exception, e:
                msg = "execption in collocation extraction => {0}{1}".format(e, _fileid)
                self.logger.write_log("error", msg)
                pass
                #raise e

        return keywords, collocations

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def do_processing(self, _filename_list):
        n = len(_filename_list)

        if n <= 0:
            return

        cdef int i = 0
        cdef int thread_num = 0
        cdef int num_threads_ = self.num_threads

        sents_full = np.empty((self.num_threads,), dtype=object)
        sents_tx = np.empty((self.num_threads,), dtype=object)
        sents_rx = np.empty((self.num_threads,), dtype=object)
        sents_full_pos = np.empty((self.num_threads,), dtype=list)
        keywords_full = np.empty((self.num_threads,), dtype=object)
        keywords_rx = np.empty((self.num_threads,), dtype=object)
        keywords_tx = np.empty((self.num_threads,), dtype=object)
        collocations_full = np.empty((self.num_threads,), dtype=object)
        collocations_rx = np.empty((self.num_threads,), dtype=object)
        collocations_tx = np.empty((self.num_threads,), dtype=object)
        textid = np.empty((self.num_threads,), dtype=object)
        result_set = np.empty((self.num_threads,), dtype=object)
        clf_result = np.empty((self.num_threads,), dtype=list)

        with nogil,parallel(num_threads=num_threads_):
            for i in prange(n, schedule='dynamic'):
                thread_num = openmp.omp_get_thread_num()
                with gil:
                    #jpype.attachThreadToJVM() -> For Hannanum, Kkma tagger
			            
                    self.logger.write_log("info", 
                        "extract keywords of %s, thread id => %d" % (_filename_list[i], thread_num))
                    try:
                        textid[thread_num] = self._get_textid_from_filename(_filename_list[i])
                    except Exception, e:
                        self.logger.write_log("error", e)

                    result_set[thread_num] = []
	
                    sents_full[thread_num], sents_tx[thread_num], sents_rx[thread_num], sents_full_pos[thread_num] \
                            = self._read_file_contents(_filename_list[i])
                    if len(sents_full[thread_num]) > 0:
                        try:
                            keywords_full[thread_num], collocations_full[thread_num] = self.__run_extraction(sents_full[thread_num], thread_num, _filename_list[i])
                            result_set[thread_num].append(["full", keywords_full[thread_num], collocations_full[thread_num]])
                        except Exception, e:
                            msg = "File => %s, exception(full sentences) => %s" % (textid[thread_num], e.args[0])
                            self.logger.write_log("warning", msg)
                            continue

                        try:
                            clf_result[thread_num] = self.clf.prediction(sents_full[thread_num])
                            self.mdb.register_classification_results(textid[thread_num],
                                    clf_result[thread_num], sents_full_pos[thread_num])
                        except Exception, e:
                            msg = "File => %s, exception(sentimental classification) => %s" % (textid[thread_num], e.args[0])
                            self.logger.write_log("error", e)
                            pass
                    else:
                        self.logger.write_log("info", "sents_full's length is 0. skipping collocations extraction of %s" % textid[thread_num])

                    if len(sents_tx[thread_num]) > 0:
                        try:
                            keywords_tx[thread_num], collocations_tx[thread_num] = self.__run_extraction(sents_tx[thread_num], thread_num, _filename_list[i])
                            result_set[thread_num].append(["tx", keywords_tx[thread_num], collocations_tx[thread_num]])
                        except Exception, e:
                            msg = "File => %s, exception(tx sentences) => %s" % (textid[thread_num], e.args[0])
                            self.logger.write_log("warning", msg)
                            pass
                    else:
                        self.logger.write_log("info", "sents_tx's length is 0. skipping collocations extraction of %s" % textid[thread_num])
					
                    if len(sents_rx[thread_num]) > 0:
                        try:
                            keywords_rx[thread_num], collocations_rx[thread_num] = self.__run_extraction(sents_rx[thread_num], thread_num, _filename_list[i])
                            result_set[thread_num].append(["rx", keywords_rx[thread_num], collocations_rx[thread_num]])
                        except Exception, e:
                            msg = "File => %s, exception(rx sentences) => %s" % (textid[thread_num], e.args[0])
                            self.logger.write_log("warning", msg)
                            pass
                    else:
                        self.logger.write_log("info", "sents_rx's length is 0. skipping collocations extraction of %s" % textid[thread_num])

                    try:
                        self.mdb.register_mining_results(textid[thread_num], result_set[thread_num])
                    except Exception, e:
                        self.logger.write_log("error", e)

            #with gil:
            #    gc.collect()

        del keywords_full, keywords_rx, keywords_tx
        del collocations_full, collocations_rx, collocations_tx
        del sents_full, sents_rx, sents_tx, sents_full_pos
        del textid
        del result_set
        del clf_result
