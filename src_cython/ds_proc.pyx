# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube co, Ltd 2017
        Writer : Jin Kak, Jung
            Revision History :
            First released on Apr, 30, 2017
"""
import logging

from cython.parallel import parallel, prange

cimport cython
cimport openmp
import os
import numpy as np

from ds import document_similarity
from dataproc import mongodb, mariadb

import weakref
from utils import log, utils
from proc_base import proc_base

class ds_proc(proc_base):

    def __init__(self, _num_threads, _log_filename, _parent, 
            _mongodb_host="localhost", _mongodb_port=27017, _mongodb_db="msens_db",
            _mariadb_host="localhost", _mariadb_port=3306, _mariadb_db="msens_db"):
        proc_base.__init__(self, _num_threads, _log_filename, _parent, \
                _mongodb_host, _mongodb_port, _mongodb_db)

        self.ds_options = property(fget=weakref.ref(self.get_ds_options), \
                fset=weakref.ref(self.set_ds_options))

        self.ds = document_similarity()
        self.ds.document_frequency = (1, 1.0)
        self.logger.write_log("info", "DS processing object initialized")
        self.rdb = {"host":_mariadb_host, "port":_mariadb_port, "database":_mariadb_db}

        self.do_vectorizing()
        
    def __del__(self):
        proc_base.__del__(self)
        self.logger.write_log("info", "DS processing object deinitialized")
        del self.ds

    def __run_extraction(self, _sentences, _thread_num, _fileid):        
        resultset = []
        for sent in _sentences:
            if len(unicode(sent)) < 2:
                continue

            result = [] 

            try:
                (_r_size, _r_threshold) = self.ds_options
            except TypeError as e:
                raise TypeError('Set document similarity factor first' + e.args[0])

            try:
                for id, cos_sim, result_sentence \
                        in self.ds.get_similar_sentences(sent, _r_size, _r_threshold):
                    result.append((id, cos_sim, result_sentence))
            except Exception, e:
                msg = "exception occurred while processing sentence simiarity => {0}".format(e)
                self.logger.write_log("error", msg)
                pass
            
            if len(result) > 0:
                resultset.append((sent, result))

        return resultset

    def get_ds_options(self):
        try:
            return (self.result_size, self.threshold)
        except AttributeError as e:
            print(e)

    def set_ds_options(self, _result_size, _threshold):
        self.result_size = _result_size
        self.threshold = _threshold

    # Select MariaDB rule data and put it into vectorizing method as a parameter
    def do_vectorizing(self):
        try:
            db = mariadb(_host=self.rdb["host"], _port=self.rdb["port"], \
                    _dbname=self.rdb["database"])

            rule_scripts = db.read_rule_script()
            del db
        except Exception, e:
            raise e

        try:
            self.ds.vectorizing(rule_scripts)
        except Exception, e:
            msg = "exception occurred while training data set => {0}".format(e)
            self.logger.write_log("error", msg)
            raise e

        self.logger.write_log("info", "script vectorizing success")

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
        textid = np.empty((self.num_threads,), dtype=object)
        resultset = np.empty((self.num_threads,), dtype=object)

        with nogil,parallel(num_threads=num_threads_):
            for i in prange(n, schedule='dynamic'):
                thread_num = openmp.omp_get_thread_num()
                with gil:
                    self.logger.write_log("info", 
                        "analyze document %s, thread id => %d" % (_filename_list[i], thread_num))
    
                    try:
                        textid[thread_num] = self._get_textid_from_filename(_filename_list[i])
                    except Exception, e:
                        self.logger.write_log("error", e)

                    sents_full[thread_num], sents_tx[thread_num], \
                            sents_rx[thread_num], sents_full_pos[thread_num] \
                            = self._read_file_contents(_filename_list[i])
                    if len(sents_tx[thread_num]) > 0:
                        try:
                            #for resultset[thread_num] in self.__run_extraction(
                            #        sents_tx[thread_num], thread_num, _filename_list[i]):
                            #    # insert to database 
                            #    self.mdb.register_sent_similarity(
                            #            textid[thread_num], resultset[thread_num])

                            resultset[thread_num] = self.__run_extraction(
                                    sents_tx[thread_num], thread_num, _filename_list[i])
                            # insert to database 
                            if len(resultset[thread_num]) > 0:
                                self.mdb.register_sent_similarity(
                                    textid[thread_num], resultset[thread_num])
                        except Exception, e:
                            msg = "File => %s, exception(tx sentences) => %s" \
                                                    % (textid[thread_num], e.args[0])
                            self.logger.write_log("warning", msg)
                            continue

        del resultset
        del textid
        del sents_full_pos
        del sents_rx
        del sents_tx
        del sents_full
