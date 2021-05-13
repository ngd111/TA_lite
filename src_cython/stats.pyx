# -*- coding: utf-8 -*-
"""
    (C) Copyright Hansol Inticube 2017
        Writer : Jin Kak, Jung
        Revision History : 
        First released on Apr, 30, 2017
"""

from dataproc import mongodb
import pandas as pd
from utils import utils

class stats(object):
    def __init__(self, _mongodb_host = "localhost", _mongodb_port = 27017, _mongodb_db = "msens_db"):
        self.mdb = mongodb(_mongodb_db, _mongodb_host, _mongodb_port)
        self.utils = utils()

    def __del__(self):
        del self.mdb
        del self.utils

    def _calculate_ranking(self, _data):
        list_order_by_ranking, dic_by_keyword = self.utils.build_rankings(_data)
        dataset_for_reg = []
        for l_ranking in list_order_by_ranking:
            dataset_for_reg.append((l_ranking[0], l_ranking[1], l_ranking[2]))

        del list_order_by_ranking, dic_by_keyword

        return dataset_for_reg

    def _filter_new_keywords(self, _dataset_f, _dataset_p):
        new_hot_keyword = []
        
        for t in _dataset_f:
            found = False
            for p in _dataset_p:
                if t[1] == p[1]:
                    found = True
            if found == False:
                new_hot_keyword.append(t)

        return new_hot_keyword

    """
        return : list, list of string type date(YYYYMMDD)
    """
    def _get_holiday(self, _month):
        holiday = self.utils.get_sunday_saturday_of_month(_month)

        return holiday

    """
        parameter : 
            _startdatehour : string(YYYYMMDDHH24)
            _enddatehour : string(YYYYMMDDHH24)
    """
    def make_keywords_hourly_stat(self, _startdatehour, _enddatehour):
        if _startdatehour > _enddatehour:
            raise ValueError("_enddatehour is less than _startdatehour, check value")

        try:
            self.mdb.run_keywords_summary(\
                    _unit='hourly', _startdate=_startdatehour, _enddate=_enddatehour)
        except Exception, e:
            raise e

    """
        parameter : 
            _startdate : string(YYYYMMDD)
            _enddate : string(YYYYMMDD)
    """
    def make_keywords_daily_stat(self, _startdate, _enddate):
        if _startdate > _enddate:
            raise ValueError("_enddate is less than _startdate, check value")

        try:
            self.mdb.run_keywords_summary(\
                    _unit='daily', _startdate=_startdate, _enddate=_enddate)
        except Exception, e:
            raise e
    
    """
        parameter : 
            _startmonth : string(YYYYMM)
            _endmonth : string(YYYYMM)
            _include_holiday : Boolean(True/False)
    """
    def make_monthly_ranking(self, _startmonth, _endmonth, _include_holiday = True):
        if _startmonth > _endmonth:
            raise ValueError("_endmonth is less than _startmonth, check value")

        if isinstance(_include_holiday, bool) == False:
            raise TypeError("_include_holiday is not bool type. check data type")

        _currentmonth = _startmonth

        while _currentmonth <= _endmonth:
            date_first = _currentmonth + "01"
            date_last = self.utils.get_last_day_of_month(date_first)

            result = []
            try:
                holiday = []
                if _include_holiday == False:
                    holiday = self._get_holiday(_currentmonth)

                for r in self.mdb.read_keywords_range_summary_stat(\
                                    date_first, date_last, holiday):
                    result.append((r['_id'], r['count']))
            except Exception, e:
                raise e

            if len(result) > 0: 
                # calculate rankings
                dataset_for_reg = self._calculate_ranking(result)

                # insert data into mongodb
                try:
                    self.mdb.register_monthly_hot_keywords(_currentmonth, dataset_for_reg)
                except Exception, e:
                    raise e

            # Increase month
            try:
                _currentmonth = self.utils.add_days(
                        self.utils.get_last_day_of_month(_currentmonth+"01"), 1)[:6]
            except Exception, e:
                raise e

    """
        parameter : 
            _startdate : string(YYYYMMDD), Date the week belongs to
            _enddate : string(YYYYMMDD), Date the week belongs to
            _include_holiday : Boolean(True/False)
    """
    def make_weekly_ranking(self, _startdate, _enddate, _include_holiday = True):
        if _startdate > _enddate:
            raise ValueError("_enddate is less than _startdate. check value")

        if isinstance(_include_holiday, bool) == False:
            raise TypeError("_include_holiday is not bool type. check data type")

        _currentdate = _startdate

        while _currentdate <= _enddate:
            date_of_sunday, date_of_saturday = self.utils.get_sunday_saturday(_currentdate)
            if _include_holiday == False:
                # Adjust start date and end date of week
                startdate = self.utils.add_days(date_of_sunday, 1)
                enddate = self.utils.add_days(date_of_saturday, -1)
            else:
                startdate = date_of_sunday
                enddate = date_of_saturday

            result = []
            try:
                for r in self.mdb.read_keywords_range_summary_stat(startdate, enddate):
                    result.append((r['_id'], r['count']))
            except Exception, e:
                raise e

            # calculate rankings
            dataset_for_reg = self._calculate_ranking(result)

            # insert data into mongodb
            try:
                # Insert Key => Use date_of_sunday, not startdate. It's important.
                self.mdb.register_weekly_hot_keywords(date_of_sunday, dataset_for_reg)
            except Exception, e:
                raise e

            # Increase week
            try:
                _currentdate = self.utils.add_days(_currentdate, 7)
            except Exception, e:
                raise e


    """
        parameter : 
            _startdate : string(YYYYMMDD)
            _enddate : string(YYYYMMDD)
    """
    def make_daily_ranking(self, _startdate, _enddate):
        if _startdate > _enddate:
            raise ValueError("_enddate is less than _startdate. check value")

        _currentdate = _startdate

        while _currentdate <= _enddate:
            result = []
            try:
                for r in self.mdb.read_keywords_daily_stat(_currentdate):
                    result.append((r['_id']['keyword'], r['count']))
            except Exception, e:
                raise e

            # calculate rankings
            dataset_for_reg = self._calculate_ranking(result)

            # insert data into mongodb
            try:
                self.mdb.register_daily_hot_keywords(_currentdate, dataset_for_reg)
            except Exception, e:
                raise e

            # extract new hot keywords(_currentdate data - _previousdate data)
            _previousdate = self.utils.add_days(_currentdate, -1)
            # read previous date data
            result = []

            try: 
                for r in self.mdb.read_keywords_daily_stat(_previousdate):
                    result.append((r['_id']['keyword'], r['count']))
            except Exception, e:
                raise e

            # calculate rankings
            dataset_for_previous_date = self._calculate_ranking(result)

            # filter new hot keywords
            dataset_new_keywords = self._filter_new_keywords(dataset_for_reg, 
                    dataset_for_previous_date)

            # insert data to mongodb
            try:
                self.mdb.register_new_daily_hot_keywords(_currentdate, dataset_new_keywords)
            except Exception, e:
                raise e

            try:
                _currentdate = self.utils.add_days(_currentdate, 1)
            except Exception, e:
                raise e

    """
        parameter : 
            _startdatehour : string(YYYYMMDDHH24)
            _enddatehour : string(YYYYMMDDHH24)
    """
    def make_hourly_ranking(self, _startdatehour, _enddatehour):
        if _startdatehour > _enddatehour:
            raise ValueError("_enddatehour is less than _startdatehour. check value")

        _currentdatehour = _startdatehour

        while _currentdatehour <= _enddatehour:
            result = []
            try:
                for r in self.mdb.read_keywords_hourly_stat(_currentdatehour):
                    result.append((r['_id']['keyword'], r['count']))
            except Exception, e:
                raise e

            # calculate rankings
            dataset_for_reg = self._calculate_ranking(result)

            # insert data into mongodb
            try:
                self.mdb.register_hourly_hot_keywords(_currentdatehour, dataset_for_reg)
            except Exception, e:
                raise e

            # extract new hot keywords(_currentdatehour data - _previousdatehour data)
            _previousdatehour = self.utils.add_hours(_currentdatehour + '0000', -24)
            # read previous date data
            result = []

            try:
                for r in self.mdb.read_keywords_hourly_stat(_previousdatehour[:10]):
                    result.append((r['_id']['keyword'], r['count']))
            except Exception, e:
                raise e

            # calculate rankings
            dataset_for_previous_date = self._calculate_ranking(result)

            # filter new hot keywords
            dataset_new_keywords = self._filter_new_keywords(dataset_for_reg,
                    dataset_for_previous_date)

            # insert data to mongodb
            try:
                self.mdb.register_new_hourly_hot_keywords(_currentdatehour, dataset_new_keywords)
            except Exception, e:
                raise e

            try:
                _currentdatehour = self.utils.add_hours(_currentdatehour+"0000", 1)
                if len(_currentdatehour) == 14:
                    _currentdatehour = _currentdatehour[:10]
            except Exception, e:
                raise e
    
    """
        comment : 현재 일자와 전일자의 데이터를 비교 등수의 변화를 체크해 순위를 세운다
        parameter :
            _startdate : string(YYYYMM)
            _enddate : string(YYYYMM)
            _sr_size : integer, the size of sharp rising keywords. limitation of return keywords
            _holiday : Default True
    """
    def make_weekly_sr_keywords(self, _startdate, _enddate, _sr_size, _holiday = True):
        if _startdate > _enddate:
            raise ValueError("_enddate is less then _startdate. check value")

        _currentdate = _startdate

        while _currentdate <= _enddate:
            date_of_sunday, date_of_saturday = self.utils.get_sunday_saturday(_currentdate)
            if _holiday == False:
                # Adjust start date and end date of week
                date_of_sunday = self.utils.add_days(date_of_sunday, 1)
                date_of_saturday = self.utils.add_days(date_of_saturday, -1)

            currentweek_result = {}
            previousweek_result = {}

            try:
                for r in self.mdb.read_weekly_hot_keywords(date_of_sunday):
                    currentweek_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            previousweekfromcurrentdate = self.utils.add_days(_currentdate, -7)
            date_of_sunday_prev, date_of_saturday_prev \
                    = self.utils.get_sunday_saturday(previousweekfromcurrentdate)
            if _holiday == False:
                # Adjust start date and end date of week
                date_of_sunday_prev = self.utils.add_days(date_of_sunday_prev, 1)
                date_of_saturday_prev = self.utils.add_days(date_of_saturday_prev, -1)

            try:
                for r in self.mdb.read_weekly_hot_keywords(date_of_sunday_prev):
                    previousweek_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            if len(currentweek_result) > 0:
                # Calculate rankings using ranking fluctuation
                rank_result = self.utils.ranking_variation_of_ranking(
                                currentweek_result, previousweek_result, _sr_size)

                # Insert data into mongodb
                try:
                    self.mdb.register_weekly_sr_keywords(date_of_sunday, rank_result)
                except Exception, e:
                    raise e

            # Increase week
            try:
                _currentdate = self.utils.add_days(_currentdate, 7)
            except Exception, e:
                raise e

    """
        comment : 현재 달과 전월 달의 데이터를 비교 등수의 변화를 체크해 순위를 세운다
        parameter :
            _startmonth : string(YYYYMM)
            _endmonth : string(YYYYMM)
            _sr_size : integer, the size of sharp rising keywords. limitation of return keywords
    """
    def make_monthly_sr_keywords(self, _startmonth, _endmonth, _sr_size):
        if _startmonth > _endmonth:
            raise ValueError("_endmonth is less than _startmonth, check value")

        _currentmonth = _startmonth

        while _currentmonth <= _endmonth:
            currentmonth_start_date = _currentmonth + "01"
            previousmonth = self.utils.add_days(currentmonth_start_date, -1)[:6]

            currentmonth_result = {}
            previousmonth_result = {}

            try:
                for r in self.mdb.read_monthly_hot_keywords(_currentmonth):
                    currentmonth_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            try:
                for r in self.mdb.read_monthly_hot_keywords(previousmonth):
                    previousmonth_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            if len(currentmonth_result) > 0:
                # Calculate rankings using ranking fluctuation
                rank_result = self.utils.ranking_variation_of_ranking(
                                currentmonth_result, previousmonth_result, _sr_size)

                # Insert data into mongodb
                try:
                    self.mdb.register_monthly_sr_keywords(_currentmonth, rank_result)
                except Exception, e:
                    raise e

            # Increase month
            try:
                _currentmonth = self.utils.add_days(
                        self.utils.get_last_day_of_month(_currentmonth+"01"), 1)[:6]
            except Exception, e:
                raise e

    """
        comment : 현재 일자와 전일자의 데이터를 비교 등수의 변화를 체크해 순위를 세운다
        parameter : 
            _startdate : string(YYYYMMDD)
            _enddate : string(YYYYMMDD)
            _sr_size : integer, the size of sharp rising keywords. limitation of return keywords
    """
    def make_daily_sr_keywords(self, _startdate, _enddate, _sr_size):
        if _startdate > _enddate:
            raise ValueError("_enddate is less than _startdate, check value")

        _currentdate = _startdate

        while _currentdate <= _enddate:
            previousdate = self.utils.add_days(_currentdate, -1)

            currentdate_result = {}
            previousdate_result = {}

            try:
                for r in self.mdb.read_daily_hot_keywords(_currentdate):
                    currentdate_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            try:
                for r in self.mdb.read_daily_hot_keywords(previousdate):
                    previousdate_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            if len(currentdate_result) > 0:
                # Calculate rankings using ranking fluctuation
                rank_result = self.utils.ranking_variation_of_ranking(
                                currentdate_result, previousdate_result, _sr_size)

                # insert data into mongodb
                try:
                    self.mdb.register_daily_sr_keywords(_currentdate, rank_result)
                except Exception, e:
                    raise e

            # Increase date
            try:
                _currentdate = self.utils.add_days(_currentdate, 1)
            except Exception, e:
                raise e

    """
        comment : 현재 시간대와 동일한 시간대의 전일자의 데이터를 비교
                  등수의 변화를 체크해 순위를 세운다
        parameter : 
            _startdatehour : string(YYYYMMDDHH24)
            _enddatehour : string(YYYYMMDDHH24)
            _sr_size : integer, the size of sharp rising keywords. limitation of return keywords
    """
    def make_hourly_sr_keywords(self, _startdatehour, _enddatehour, _sr_size):
        if _startdatehour > _enddatehour:
            raise ValueError("_enddatehour is less than _startdatehour. check value")

        _currentdatehour = _startdatehour

        while _currentdatehour <= _enddatehour:
            previousdatehour = self.utils.add_hours(_currentdatehour + "0000", -24)
            if len(previousdatehour) == 14:
                previousdatehour = previousdatehour[:10]

            currentdatehour_result = {}
            previousdatehour_result = {}

            try:
                for r in self.mdb.read_hourly_hot_keywords(_currentdatehour):
                    currentdatehour_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            try:
                for r in self.mdb.read_hourly_hot_keywords(previousdatehour):
                    previousdatehour_result[r['keyword']] = r['rank']
            except Exception, e:
                raise e

            if len(currentdatehour_result) > 0:
                # Calculate rankings using ranking fluctuation
                rank_result = self.utils.ranking_variation_of_ranking(
                                 currentdatehour_result, previousdatehour_result, _sr_size)

                # insert data into mongodb
                try:
                    self.mdb.register_hourly_sr_keywords(_currentdatehour, rank_result)
                except Exception, e:
                    raise e

            # Increase hour
            try:
                _currentdatehour = self.utils.add_hours(_currentdatehour+"0000", 1)
                if len(_currentdatehour) == 14:
                    _currentdatehour = _currentdatehour[:10]
            except Exception, e:
                raise e

