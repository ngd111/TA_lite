#! /usr/bin/python
# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube Ltd,
    Writer : Jin Kak, Jung
    Revision History :
        First released on Apr, 30, 2017
"""

from apscheduler.schedulers.background import BackgroundScheduler
from app_base import app_base
from stats import stats
import signal
import time, sys

from utils import log

import json

class statsmain(app_base):

    global log_filename

    def __init__(self, _name):
        global process_name
        global log_filename

        process_name = _name
        self._read_config("./" + process_name + ".conf")
        log_filename = self.dir_log + "/" + process_name + ".log"

        super(statsmain, self).__init__(_use_directory_watcher = False)

    def __enter__(self):
        self.logger = log(process_name.upper() + " main", log_filename)
        self.st = stats(_mongodb_host=self.db_host, \
                _mongodb_port=self.db_port, _mongodb_db=self.database)
        self.sched = BackgroundScheduler()

        # set signal handler
        signal.signal(signal.SIGTERM, self.signal_handler)

        self.utils.write_pid_of_process("hst")
        self.logger.write_log("info", "Enter to stats. app")

    def __exit__(self, type, value, traceback):
        del self.st
        self.logger.write_log("info", "Exit from stats. app")

    def signal_handler(self, signal, frame):
        self.logger.write_log("warning", "signal caught %d" % signal)
        if signal == 15:
            self.sched.shutdown()
            self.utils.delete_pid_file("hst")
            sys.exit()

    def _read_config(self, _filename):
        try:
            with open(_filename) as f:
                data = json.load(f)
            self.dir_log = data["directory"]["log"]
            self.db_host = data["mdb"]["host"]
            self.db_port = data["mdb"]["port"]
            self.database = data["mdb"]["database"]
            self.sropt_month = data["sr_options"]["include_current_month"]
            self.sropt_week  = data["sr_options"]["include_current_week"]
            self.sropt_today = data["sr_options"]["include_today"]
            self.sropt_holiday = data["sr_options"]["include_holiday"]
            self.sropt_keywords_limit = data["sr_options"]["keywords_size"]
        except Exception as e:
            raise e

    # run every 1 hour
    # current date daily, current hour-1, 1 hour interval
    #  - keywords_hourly_stat
    #  - keywords_daily_stat
    #  - hourly_hot_keywords
    #  - daily_hot_keywords
    #  - hourly_sr_keywords
    #  - daily_sr_keywords
    def _current_timeline_jobs(self):
        self.logger.write_log("info", "hourly archive start")
        # hourly(processing -1 hour data range)
        startdatehour = self.utils.get_current_timeline_datehour()
        enddatehour = startdatehour

        message = "startdatehour=>{0}, enddatehour=>{1}".format(startdatehour, enddatehour)
        self.logger.write_log("info", message)

        try:
            self.st.make_keywords_hourly_stat(startdatehour, enddatehour)
            self.st.make_hourly_ranking(startdatehour, enddatehour)
            self.st.make_hourly_sr_keywords(startdatehour, enddatehour, self.sropt_keywords_limit)
        except Exception, e:
            raise e

        #if startdatehour[:8] == self.utils.get_today():
        # daily(processing current day data)
        try:
            self.st.make_keywords_daily_stat(startdatehour[:8], enddatehour[:8])
            self.st.make_daily_ranking(startdatehour[:8], enddatehour[:8])
            if self.sropt_today == True:
                self.st.make_daily_sr_keywords(startdatehour[:8], enddatehour[:8],
                        self.sropt_keywords_limit)
        except Exception, e:
            raise e

        self.logger.write_log("info", "hourly archive finished")

    # calc. current weekly and monthly, 1 day interval
    #  - daily_sr_keywords (in case of sropt_today == False)
    #  - weekly_hot_keywords
    #  - weekly_sr_keywords
    #  - monthly_hot_keywords
    #  - monthly_sr_keywords
    def _past_timeline_daily_jobs(self):
        self.logger.write_log("info", "daily archive start")
        startdate = self.utils.get_yesterday()
        enddate = startdate

        message = "startdate=>{0}, enddate=>{1}".format(startdate, enddate)
        self.logger.write_log("info", message)

        try:
            if self.sropt_today == False:
                self.st.make_daily_sr_keywords(startdate, enddate, self.sropt_keywords_limit)

            self.st.make_weekly_ranking(startdate, enddate)
            if self.sropt_week == True:
                self.st.make_weekly_sr_keywords(startdate, enddate, self.sropt_keywords_limit)

            self.st.make_monthly_ranking(startdate[:6], enddate[:6])
            if self.sropt_month == True:
                self.st.make_monthly_sr_keywords(startdate[:6], enddate[:6],
                        self.sropt_keywords_limit)
        except Exception, e:
            raise e

        self.logger.write_log("info", "daily archive finished")

    # calc. previous weekly, from start date of week to last date of week, 1 week interval
    # Re-calc. and re-write weekly data
    #  - weekly_hot_keywords
    #  - weekly_sr_keywords
    def _past_timeline_weekly_jobs(self):
        self.logger.write_log("info", "weekly archive start")
        startdate = self.utils.get_yesterday()
        enddate = startdate

        message = "startdate=>{0}, enddate=>{1}".format(startdate, enddate)
        self.logger.write_log("info", message)

        try:
            self.st.make_weekly_ranking(startdate, enddate)
            if self.sropt_week == False:
                self.st.make_weekly_sr_keywords(startdate, enddate, self.sropt_keywords_limit)
        except Exception, e:
            raise e

        self.logger.write_log("info", "weekly archive finished")

    # calc. previous monthly, from last month day 1 to last date of last month, 1 month interval
    # Re-calc. and re-write monthly data
    #  - monthly_hot_keywords
    #  - monthly_sr_keywords
    def _past_timeline_monthly_jobs(self):
        self.logger.write_log("info", "monthly archive start")
        startdate = self.utils.get_yesterday()
        enddate = startdate

        message = "startdate=>{0}, enddate=>{1}".format(startdate, enddate)
        self.logger.write_log("info", message)

        try:
            self.st.make_monthly_ranking(startdate[:6], enddate[:6])
            if self.sropt_month == False:
                self.st.make_monthly_sr_keywords(startdate[:6], enddate[:6],
                        self.sropt_keywords_limit)
        except Exception, e:
            raise e

        self.logger.write_log("info", "monthly archive finished")

    def register_jobs(self):
        self.logger.write_log("info", "register jobs started")
        # every 1 hour 0:10, 1:10, 2:10, ....
        self.sched.add_job(self._current_timeline_jobs, 'cron', minute=10)
        # every 1 day 1:00
        self.sched.add_job(self._past_timeline_daily_jobs, 'cron', hour=1, minute=0)
        # every 1 week(mon) 2:00
        self.sched.add_job(self._past_timeline_weekly_jobs, 'cron', \
                day_of_week='mon', hour=2, minute=0)
        # every 1 month  YYYY-MM-01, 3:00
        self.sched.add_job(self._past_timeline_monthly_jobs, 'cron', day=1, hour=3, minute=0)
        self.logger.write_log("info", "register jobs finished")

    def run(self):
        self.register_jobs()

        self.sched.start()
        while True:
            time.sleep(2)

if __name__=="__main__":
    reload(sys)
    sys.setdefaultencoding('utf-8')

    app = statsmain("stats")

    with app:
        app.run()

    del app
    sys.exit(0)
