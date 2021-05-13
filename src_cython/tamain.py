#! /usr/bin/python
# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube Ltd,
    Writer : Jin Kak, Jung
    Revision history : 
        First released on March, 31, 2017
"""
# Import OS related packages
from os import listdir
from os.path import isfile #, join
import signal, sys, time

# Import TA processing class
from ta_proc import ta_proc
from app_base import app_base, directory_watcher

import json
import gc

from utils import log

class tamain(app_base):

    def __init__(self, _name):
        global process_name
        global log_filename
        global data_directory

        process_name = _name
        self._read_config("./" + process_name + ".conf")
        log_filename = self.dir_log + "/" + process_name + ".log"
        data_directory = self.dir_data

        self.reload_dictionary = False
        self.re_training = False

        super(tamain, self).__init__(
                _use_directory_watcher = True, _directory_name = data_directory)

    def __enter__(self):
        self.logger = log(process_name.upper() + " main", log_filename)

        #self.tp = ta_proc(4, log_filename, self, _mongodb_host="211.179.3.198", _mongodb_port=5050)
        self.tp = ta_proc(_num_threads=self.cores, _log_filename=log_filename, _parent=self,
                _mongodb_host=self.db_host, _mongodb_port=self.db_port, _mongodb_db=self.database)
        # set signal handler
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGUSR1, self.signal_handler)
        signal.signal(signal.SIGUSR2, self.signal_handler)

        self.utils.write_pid_of_process("hta")
        self.logger.write_log("info", "Enter to app")

    def __exit__(self, type, value, traceback):
        self.logger.write_log("info", "Exit from app")
        #super(App, self).__del__()
        self._release_resource()

    def _release_resource(self):
        if (self.tp != None):
            del self.tp
        if (self.logger != None):
            del self.logger

    def _read_config(self, _filename):
        try:
            with open(_filename) as f:
                data = json.load(f)
            self.cores = data["parallel"]["cores"]
            self.db_host = data["mdb"]["host"]
            self.db_port = data["mdb"]["port"]
            self.database = data["mdb"]["database"]
            self.dir_log = data["directory"]["log"]
            self.dir_data = data["directory"]["data"]
        except Exception as e:
            print 'exception : ', e
            raise e

    def signal_handler(self, signal, frame):
        self.logger.write_log("warning", "signal caught %d" % signal)
        if signal == 15:
            self.exit_directory_watcher_thread = True
        elif signal == 10:
            self.reload_dictionary = True
        elif signal == 12:
            self.re_training = True

    #@profile 
    def run(self):
        self.dw.notifier.start()
        while True:
            #print ('----- Start gathering file list ------')
            filenames = []
            while not self.dw.q_files.empty():
                filename = self.dw.q_files.get()
                if filename[-4:] == '.swp' or filename[-5:] == '.swpx':
                    pass
                else:
                    filenames.append(filename)
                #if (filename[-3:] == 'csv'):
                #    filenames.append(filename)
                #else:
                #    # remove file(not allowed type of file)
                #    pass
                self.dw.q_files.task_done()

            # read queue data
            #filenames = [data_path + f for f in listdir('../data/msens/') if
            #        isfile(join('../data/msens/', f)) if f[-3:] == 'csv']

            if len(filenames) > 0:
                self.tp.do_processing(filenames)
            if self.exit_directory_watcher_thread == True:
                self.dw.q_files.join()
                break

            if self.reload_dictionary == True:
                try:
                    self.tp.do_reload_dictionary()
                except Exception, e:
                    self.logger.write_log("error", e)
                finally:
                    self.reload_dictionary = False;

            if self.re_training == True:
                try:
                    self.tp.do_training()
                except Exception, e:
                    self.logger.write_log("error", e)
                finally:
                    self.re_training = False

            time.sleep(1)

        self.dw.notifier.stop()
        self.utils.delete_pid_file("hta")



if __name__=='__main__':
    reload(sys)
    sys.setdefaultencoding('utf-8')

    app = tamain("ta")

    with app:
        app.run()

    del app
    gc.collect()
    sys.exit(0)

