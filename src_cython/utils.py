#-*- encoding:utf-8 -*-
from itertools import groupby
from datetime import datetime, timedelta, date
import logging
import logging.handlers
import cchardet
import os

class utils:
    def enum(*sequential, **named):
        enums = dict(zip(sequential, range(len(sequential))), **named)
        reverse = dict((value,key) for key, value in enums.iteritems())
        enums['reverse_mapping'] = reverse
        return type('Enum', (), enums)

    """
        parameters : 
            _data : list[tuple(value, score)] ; The score must be a number(int, long, float ...)
                ex) [('a',1.23), ('b',2.5), ('c', 0.91), ('d', 1.3), ('e', 1.3)]
        returns :
            rankings : list[tuple(rank, value)]
                ex) [(0, 'b'), (1, 'd'), (1, 'e'), (3, 'a'), (4, 'c')]
            keywords_ranks : dict{value:rank}
                ex) {'b':0, 'd':1, ....}
    """
    def build_rankings(self, _data):
        sorted_data = sorted(_data, key=lambda x: -x[1])
        rankings = []
        keywords_ranks = {}
        rank = 0
        for k, v in groupby(sorted_data, lambda x: x[1]): # group by score
            grp = [(rank, tup[0], tup[1]) for tup in v] # get item tup[0] and put it in a tuple with the rank
            rankings += grp
            for g in grp:
                keywords_ranks[g[1]] = g[0]
            rank += len(grp) # increase rank for next grouping

        return rankings, keywords_ranks

    """
        parameters : 
            _current_rankingdata, _previous_rankingdata : 
                    dict [key] = value ; key -> keyword, value -> rank
                ex) {u'자동이체':3, u'완납':1, u'대출':0, u'최저보증':3, ...}
            return size : integer
        returns :
            _rankings : list[tuple(keyword, rank)]
                ex) [(u'대출',3),(u'수익률',0),(u'완납',-1), ...]              
    """
    def ranking_variation_of_ranking(self, _current_rankingdata, _previous_rankingdata,
            _return_size = 20):
        rank_fluctuation = []
        r_size = 0

        for k, v in _current_rankingdata.iteritems():
            if r_size >= _return_size:
                break

            try:
                prev_rank = _previous_rankingdata[k]
            except KeyError, e:
                continue

            # if value is greater then 0. rank + 
            # else rank -
            fluct_rank = prev_rank - v
            rank_fluctuation.append((k, fluct_rank))
            r_size = r_size + 1

        return sorted(rank_fluctuation, key=lambda x: -x[1])   

    def write_pid_of_process(self, _filename):
        try:
            _pid = os.getpid()
            fname = "./" + _filename + ".pid"
            with open(fname, 'w') as f:
                f.write(str(_pid))
        except IOError as e:
            print("error", e)
            raise e

    def read_pid_of_process(self, _filename):
        try:
            fname = "./" + _filename + ".pid"
            with open(fname, 'r') as f:
                _pid = f.read()
        except IOError as e:
            print("error", e)
            raise e

        return int(_pid)

    def delete_pid_file(self, _filename):
        try:
            fname = "./" + _filename + ".pid"
            os.remove(fname)
        except IOError as e:
            print("error", e)
            raise e

    def convert_encoding(self, _string_data, _new_coding='UTF-8'):
        try:
            encoding = cchardet.detect(_string_data)['encoding']
            if encoding == None:
                return _string_data
            if _new_coding.upper() != encoding.upper():
                _string_data = _string_data.decode(encoding, _string_data).encode(_new_coding)
        #except TypeError as e:
        except Exception as e:
            raise e

        return _string_data

    
    """
        parameters : 
            _date : string(YYYYMMDD)
                ex) "20160801"
            _days : int
                ex) 1
        returns :
            date : string(YYYYMMDD)
                ex) "20160802"
    """
    def add_days(self, _datestring, _days):
        if len(_datestring) != 8:
            raise ValueError("Invalid date string. Valid format => YYYYMMDD")

        try:
            _dt = datetime.strptime(_datestring, "%Y%m%d")
            _r_dt = _dt + timedelta(days=_days)
        except Exception, e:
            raise e

        return _r_dt.strftime("%Y%m%d")

    """
        parameters : 
            _date : string(YYYYMMDDHH24MISS)
                ex) "20160801100000"
            _hours : int
                ex) 1
        returns :
            date : string(YYYYMMDDHH24MISS)
                ex) "20160802110000"
    """
    def add_hours(self, _datestring, _hours):
        if len(_datestring) != 14:
            raise ValueError("Invalid date string. Valid format => YYYYMMDDHH24MISS")

        try:
            _dt = datetime.strptime(_datestring, "%Y%m%d%H%M%S")
            _r_dt = _dt + timedelta(hours=_hours)
        except Exception, e:
            raise e

        return _r_dt.strftime("%Y%m%d%H%M%S")

    """
        parameters : 
            _date : string(YYYYMMDD)
                ex) "20160801"
        returns : 
            weekday : int
                ex) 0(monday) ~ 6(sunday)
    """
    def get_weekday(self, _date):
        if len(_date) != 8:
            raise ValueError("Invalid date string. Valid format => YYYYMMDD")

        dt = datetime(int(_date[0:4]), int(_date[4:6]), int(_date[6:8]))
        return dt.weekday()

    """
        parameters : 
            _date : string(YYYYMMDD), current date of month
                ex) "20160801"
            _return_type : string, value = "string", "date"
        returns : 
            lastday : string(YYYYMMDD), last date of month
                ex) "20160831"
    """
    def get_last_day_of_month(self, _date, _return_type="string"):
        if len(_date) != 8:
            raise ValueError("Invalid date string. Valid format => YYYYMMDD")

        if _return_type != "string" and _return_type != "date":
            raise ValueError("Invalid return type. Valid value => \"string\" or \"date\"")

        dt = date(int(_date[0:4]), int(_date[4:6]), int(_date[6:8]))
        next_month = dt.replace(day=28) + timedelta(days=4)
        dt_r = next_month - timedelta(days=next_month.day)
        if _return_type == "date":
            return dt_r
        else:
            return dt_r.strftime("%Y%m%d")

    """
        parameters : 
            _yearmonth : string(YYYYMM)
                ex) "201608"
        returns : 
            sundays and saturdays : list, unsorted date list
                ex) ["20160702", "20160703", "20160709", "20160710", ...]
    """
    def get_sunday_saturday_of_month(self, _yearmonth):
        date_of_holiday = []        
        # first date of month
        d_first = date(int(_yearmonth[:4]), int(_yearmonth[4:6]), 1)
        # last date of month    
        d_last = self.get_last_day_of_month(d_first.strftime("%Y%m%d"), _return_type="date")    
        d_sunday = d_first + timedelta(days = 6 - d_first.weekday())  # first sunday
        while d_sunday <= d_last:        
            date_of_holiday.append(d_sunday.strftime("%Y%m%d"))
            d_saturday = d_sunday - timedelta(days = 1)
            if d_saturday >= d_first:
                date_of_holiday.append(d_saturday.strftime("%Y%m%d"))
            d_sunday += timedelta(days=7)

        d_saturday = d_sunday - timedelta(days = 1)
        if d_saturday <= d_last:
            date_of_holiday.append(d_saturday.strftime("%Y%m%d"))
        return date_of_holiday

    """
        parameters : 
            _date : string(YYYYMMDD), current date of week
                ex) "20160801"
        returns : 
            sunday   : string(YYYYMMDD), start date of week
            saturday : string(YYYYMMDD), end date of week
    """
    def get_sunday_saturday(self, _date):
        if len(_date) != 8:
            raise ValueError("Invalid date string. Valid format => YYYYMMDD")
        dt = date(int(_date[0:4]), int(_date[4:6]), int(_date[6:8]))
        d = dt.toordinal()
        sunday = d - (d % 7)
        saturday = sunday + 6
        return date.fromordinal(sunday).strftime("%Y%m%d"), \
               date.fromordinal(saturday).strftime("%Y%m%d")

    """
        parameters : 
            _date : string(YYYYMMDD), current date of week
                ex) "20160801"
        returns : 
            sunday   : string(YYYYMMDD), date of monday of the week
            saturday : string(YYYYMMDD), date of friday of the week
    """
    def get_monday_friday(self, _date):
        if len(_date) != 8:
            raise ValueError("Invalid date string. Valid format => YYYYMMDD")
        weekday = self.get_weekday(_date)
        monday = self.add_days(_date, -weekday)
        friday = self.add_days(_date, 4-weekday)
        return monday, friday

    def get_current_timeline_datehour(self):
        _datehour = datetime.now().strftime("%Y%m%d%H")
        return self.add_hours(_datehour + "0000", -1)[:10]

    """
        returns :
            today   : string(YYYYMMDD), system time based date
    """
    def get_today(self):
        return datetime.now().strftime("%Y%m%d")

    def get_yesterday(self):
        return self.add_days(self.get_today(), -1)


class log(object):

    def __init__(self, _loggerName, _logFileName):
        #self.logger = logging.getLogger(_loggerName)
        self.logger = logging.getLogger()
        self.logger.setLevel(logging.DEBUG)
        filehandler = logging.handlers.RotatingFileHandler(_logFileName, mode='a',
                maxBytes=100*1024, backupCount=2, encoding="UTF-8")

        #filehandler = logging.FileHandler(_logFileName, "a", encoding="UTF-8")
        filehandler.setLevel(logging.INFO)

        streamhandler = logging.StreamHandler()
        streamhandler.setLevel(logging.INFO)

        formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
        filehandler.setFormatter(formatter)

        self.logger.addHandler(filehandler)
        self.logger.addHandler(streamhandler)

    def __del__(self):
        try:
            del self.logger
        except NameError as e:
            print('exception: ', e.args)

    def write_log(self, _level, _text):
        if _level == "info":
            self.logger.info(_text)
        elif _level == "warning":
            self.logger.warning(_text)
        elif _level == "error":
            self.logger.error(_text)
        elif _level == "critical":
            self.logger.critical(_text)
        elif _level == "debug":
            self.logger.debug(_text)
        else:
            raise ValueError("_level must be set one of [\"info\", \"warning\", \"error\", \"critical\", \"debug\"]")
