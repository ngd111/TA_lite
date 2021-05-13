#-*- encoding:utf-8 -*-

from pymongo import MongoClient
import pymysql
import pymongo
from collections import defaultdict
from utils import utils


class mongodb(object):

    TEXTID_MIN_LEN = 15 

    def __init__(self, _dbname, _host = "localhost", _port = 27017):
        self.client = MongoClient(_host, _port)
        self.db = self.client[_dbname]
        self.utils = utils()

    def __del__(self):
        self.client.close()
        del self.utils

    """
        parameters : 
            _textid : string, document id
            _result_set : list[[sentence string, y string, prediction_prob [float, ...]] ...]
            _pos : list[(start, end), ....], positions of recording
    """
    def register_classification_results(self, _textid, _result_set, _pos):
        if len(_textid) < self.TEXTID_MIN_LEN:
            raise ValueError("_textid length is too short. Valid format => Extn#+YYYYMMDDHH24MISS")
       
        query = {"_id":_textid}
        update_fields = {}
        update_fields["calldate"] = _textid[len(_textid)-14:]

        update_result = []
        for idx, r_set in enumerate(_result_set):
            if len(r_set[1]) > 0:
                p_set = {}
                p_set["start"] = _pos[idx][0]
                p_set["end"]   = _pos[idx][1]
                update_result.append({"sentence":r_set[0], "predicted":r_set[1], \
                        "position":p_set, "probability":r_set[2]})

        update_fields["sentimental"] = {"result" : update_result}

        try:
            self.db.classification_result.update(query, update_fields, upsert=True)
        except Exception, e:
            raise e

    """
        parameters : 
            _textid : string, document id
            _result_set : list[(target sentence string, [(sentence string, float similarity), ...]),
                               (...), ... ]
    """
    def register_sent_similarity(self, _textid, _result_set):
        if len(_textid) < self.TEXTID_MIN_LEN:
            raise ValueError("_textid length is too short. Valid format => Extn#+YYYYMMDDHH24MISS")

        query = {"_id":_textid}
        update_fields = {}
        update_fields["calldate"] = _textid[len(_textid)-14:]

        update_result = []
        
        for r_set in _result_set:
            candidates = []
            for c_set in r_set[1]:
                candidates.append({"sentence":c_set[2], "rate":c_set[1], "id":c_set[0]})
            update_result.append({"target_sentence":r_set[0],"candidates":candidates})

        #update_fields["similarity"] = {"result" : update_result}
        update_fields["similarity"] = update_result

        try:
            self.db.sentence_similarity.update(query, update_fields, upsert=True)
        except Exception, e:
            raise e

    """
        parameters : 
            _textid : document id
            _result_set : list[[rxtx string, keywords list, collocation list] ...]
                ex) [ ["full", ["keyword", ...], ["collocations", ...] ], 
                      ["rx", ["keyword", ...], ["collocations", ...] ], 
                      ["tx", ["keyword", ...], ["collocations", ...] ] ]
                * collocations 
                  See collocation_extraction._convert_results_horizontally function documentation
    """
    def register_mining_results(self, _textid, _result_set):
        if len(_textid) < self.TEXTID_MIN_LEN:
            raise ValueError("_textid length is too short. Valid format => Extn#+YYYYMMDDHH24MISS")

        query = {"_id":_textid}
        update_fields = {}
        update_fields["calldate"] = _textid[len(_textid)-14:]

        for r_set in _result_set:
            #if len(r_set) != 3:
            #    raise ValueError("Member of _result_set length must be 3. not %d" % len(r_set))

            update_keywords = []
            for k in r_set[1]:
                update_keywords.append({"word":k[0], "weight" : k[1]})

            update_collocations = []
            if isinstance(r_set[2], defaultdict) == False:
                #raise TypeError('_collocations type is not collections.defaultdict')
                pass
            else:
                for t in r_set[2].items():
                    if len(t) < 2:
                        raise ValueError('collocation words count is less then 2')
                    else:
                        if isinstance(t[0], unicode) == False:
                            raise TypeError('collocation dictionary key is not unicode string')
                        if isinstance(t[1], list) == False:
                            raise TypeError('collocation dictionary value is not list type')

                    w_list = [tm for tm in t[1]] 
                    update_collocations.append({"ref_word":t[0], "col_words":w_list})

            update_fields[r_set[0]] = {"keywords":update_keywords, "collocations":update_collocations}

        try:
            self.db.mining_result.update(query, update_fields, upsert=True)
            self.db.mining_result.create_index([('calldate', pymongo.TEXT)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _workmonth : string 'YYYYMM'
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_monthly_hot_keywords(self, _workmonth, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.monthly_hot_keywords.remove({"calldate":_workmonth})
            for d in _dataset:
                self.db.monthly_hot_keywords.insert({
                         "calldate" : _workmonth,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                    })
            self.db.monthly_hot_keywords.create_index([('calldate', pymongo.ASCENDING)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date_of_monday : string 'YYYYMMDD'
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_weekly_hot_keywords(self, _date_of_sunday, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.weekly_hot_keywords.remove({"calldate":_date_of_sunday})
            for d in _dataset:
                self.db.weekly_hot_keywords.insert({
                         "calldate" : _date_of_sunday,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                    })
            self.db.weekly_hot_keywords.create_index([('calldate', pymongo.ASCENDING)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMMDD', date of hot keywords
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_daily_hot_keywords(self, _date, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.daily_hot_keywords.remove({"calldate":_date})
            for d in _dataset:
                self.db.daily_hot_keywords.insert({
                         "calldate" : _date,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                        })
            self.db.daily_hot_keywords.create_index([('calldate', pymongo.ASCENDING)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMMDDHH24', date of hot keywords
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_hourly_hot_keywords(self, _datehour, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.hourly_hot_keywords.remove({"calldate":_datehour})
            for d in _dataset:
                self.db.hourly_hot_keywords.insert({
                         "calldate" : _datehour,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                        })
            self.db.hourly_hot_keywords.create_index([('calldate', pymongo.ASCENDING), \
                ('keyword', pymongo.ASCENDING)], unique=True, name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMMDDHH24', date of hot keywords
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_new_hourly_hot_keywords(self, _datehour, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        if len(_datehour) != 10:
            raise ValueError("Invalid datehour string. _datehour length should be 10. \
                    Valid format => YYYYMMDDHH24")

        try:
            self.db.new_hourly_hot_keywords.remove({"calldate":_datehour})
            for d in _dataset:
                self.db.new_hourly_hot_keywords.insert({
                         "calldate" : _datehour,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                        })
            self.db.new_hourly_hot_keywords.create_index([('calldate', pymongo.ASCENDING), \
                ('keyword', pymongo.ASCENDING)], unique=True, name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMMDD', date of hot keywords
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_new_daily_hot_keywords(self, _date, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        if len(_date) != 8:
            raise ValueError("Invalid date string. _date length should be 8. \
                    Valid format => YYYYMMDD")

        try:
            self.db.new_daily_hot_keywords.remove({"calldate":_date})
            for d in _dataset:
                self.db.new_daily_hot_keywords.insert({
                         "calldate" : _date,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                        })
            self.db.new_daily_hot_keywords.create_index([('calldate', pymongo.ASCENDING), \
                ('keyword', pymongo.ASCENDING)], unique=True, name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _startdate_of_week : string 'YYYYMMDD', date of hot keywords
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_new_weekly_hot_keywords(self, _startdate_of_week, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        if len(_startdate_of_week) != 8:
            raise ValueError("Invalid date string. _startdate_of_week length should be 8. \
                    Valid format => YYYYMMDD")

        try:
            self.db.new_weekly_hot_keywords.remove({"calldate":_startdate_of_week})
            for d in _dataset:
                self.db.new_weekly_hot_keywords.insert({
                         "calldate" : _startdate_of_week,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                        })
            self.db.new_weekly_hot_keywords.create_index([('calldate', pymongo.ASCENDING), \
                ('keyword', pymongo.ASCENDING)], unique=True, name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _workmonth : string 'YYYYMM'
            _dataset : dataset to be registered
                        list[tuple(ranking, keyword, count)]
    """
    def register_new_monthly_hot_keywords(self, _workmonth, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        if len(_workmonth) != 6:
            raise ValueError("Invalid date string. _workmonth length should be 6. \
                    Valid format => YYYYMM")

        try:
            self.db.new_monthly_hot_keywords.remove({"calldate":_workmonth})
            for d in _dataset:
                self.db.new_monthly_hot_keywords.insert({
                         "calldate" : _workmonth,
                         "rank" : d[0],
                         "keyword" : d[1],
                         "count" : d[2]
                        })
            self.db.new_monthly_hot_keywords.create_index([('calldate', pymongo.ASCENDING), \
                ('keyword', pymongo.ASCENDING)], unique=True, name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMM', month of SR keywords
            _dataset : dataset to be registered
                        list[tuple(keyword, ranking)]
    """
    def register_monthly_sr_keywords(self, _date, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.monthly_sr_keywords.remove({"calldate":_date})
            for d in _dataset:
                self.db.monthly_sr_keywords.insert({
                         "calldate" : _date,
                         "keyword" : d[0],
                         "rank" : d[1]
                        })
            self.db.monthly_sr_keywords.create_index([('calldate', pymongo.ASCENDING)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMMDD', date of SR keywords
            _dataset : dataset to be registered
                        list[tuple(keyword, ranking)]
    """
    def register_weekly_sr_keywords(self, _date, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.weekly_sr_keywords.remove({"calldate":_date})
            for d in _dataset:
                self.db.weekly_sr_keywords.insert({
                         "calldate" : _date,
                         "keyword" : d[0],
                         "rank" : d[1]
                    })
            self.db.weekly_sr_keywords.create_index([('calldate', pymongo.ASCENDING)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMMDD', date of SR keywords
            _dataset : dataset to be registered
                        list[tuple(keyword, ranking)]
    """
    def register_daily_sr_keywords(self, _date, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.daily_sr_keywords.remove({"calldate":_date})
            for d in _dataset:
                self.db.daily_sr_keywords.insert({
                         "calldate" : _date,
                         "keyword" : d[0],
                         "rank" : d[1]
                    })
            self.db.daily_sr_keywords.create_index([('calldate', pymongo.ASCENDING)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _date : string 'YYYYMMDDHH24', date of hot keywords
            _dataset : dataset to be registered
                        list[tuple(keyword, ranking)]
    """
    def register_hourly_sr_keywords(self, _datehour, _dataset):
        if isinstance(_dataset, list) == False:
            raise TypeError('_dataset type must be list')

        try:
            self.db.hourly_sr_keywords.remove({"calldate":_datehour})
            for d in _dataset:
                self.db.hourly_sr_keywords.insert({
                         "calldate" : _datehour,
                         "keyword" : d[0],
                         "rank" : d[1]
                    })
            self.db.hourly_sr_keywords.create_index([('calldate', pymongo.ASCENDING)], name='calldate_')
        except Exception, e:
            raise e

    """
        parameters : 
            _unit : string 'daily' or 'hourly'
            _startdate : string 'YYYYMMDD' or 'YYYYMMDDHH24', start date[time] to be summarized
            _enddate : string 'YYYYMMDD' or 'YYYYMMDDHH24', end date[time] to be summarized
    """
    def run_keywords_summary(self, _unit, _startdate, _enddate):
        if _unit != "daily" and _unit != "hourly":
            raise ValueError("Invalid _unit option : Possible values are \"daily\" or \"hourly\"")

        if _unit == "daily" and (len(_startdate) != 8 or len(_enddate) != 8):
            raise ValueError("Check _stardate or _enddate value. Required format => YYYYMMDD")

        if _unit == "hourly" and (len(_startdate) != 10 or len(_enddate) != 10):
            raise ValueError("Check _stardate or _enddate value. Required format => YYYMMDDHH24")

        if _startdate > _enddate:
            raise ValueError("_enddate is less than _startdate. check value")


        if _unit == "daily":
            _currentdate = _startdate

            while _currentdate <= _enddate:

                self.db.keywords_daily_stat.remove({"_id.calldate":_currentdate})

                try:
                    self.db.keywords_daily_stat.insert_many(
                            self.db.mining_result.aggregate(
                                [
                                    { "$match":
                                        {"calldate": {"$gte": _currentdate+"000000", \
                                                      "$lte": _currentdate+"235959"}}
                                    },
                                    { "$project":
                                        {
                                            "keywords" : "$full.keywords",
                                            "calldate" : { "$substr" : ["$calldate", 0, 8]}
                                        }
                                    },
                                    { "$unwind": "$keywords"},
                                    { "$group": {
                                            "_id" : {"keyword": "$keywords.word",
                                                   "calldate": "$calldate"
                                                  },
                                            "count" : {"$sum": 1}
                                            }
                                    },
                                    { "$sort": {"_id.calldate":1, "count":-1} }
                                ]
                                )
                            )
                    #self.db.keywords_daily_stat.insert_many(p for p in agg_result)
                    #self.db.keywords_daily_stat.insert_many(agg_result)
                    self.db.keywords_daily_stat.create_index([("_id.calldate", pymongo.ASCENDING)],
                            name="_id.calldate_")
                except Exception, e:
                    if e.args[0] == "No operations to execute":
                        pass
                    else:
                        raise e

                try:
                    _currentdate = self.utils.add_days(_currentdate, 1)
                except Exception, e:
                    raise e

        else:
            # hourly
            _currentdate = _startdate

            while _currentdate <= _enddate:

                self.db.keywords_hourly_stat.remove({"_id.calldate":_currentdate})

                try:
                    self.db.keywords_hourly_stat.insert_many(
                            self.db.mining_result.aggregate(
                                [
                                    { "$match":
                                        {"calldate": {"$gte": _currentdate+"0000", \
                                                      "$lte": _currentdate+"5959"}}
                                    },
                                    { "$project":
                                        {
                                            "keywords" : "$full.keywords",
                                            "calldate" : { "$substr" : ["$calldate", 0, 10]}
                                        }
                                    },
                                    { "$unwind": "$keywords"},
                                    { "$group": {
                                            "_id" : {"keyword": "$keywords.word",
                                                   "calldate": "$calldate"
                                                  },
                                            "count" : {"$sum": 1}
                                            }
                                    },
                                    { "$sort": {"_id.calldate":1, "count":-1} }
                                ]
                                )
                            )
                    self.db.keywords_hourly_stat.create_index([("_id.calldate", pymongo.ASCENDING)],
                            name="_id.calldate_")
                except Exception, e:
                    if e.args[0] == "No operations to execute":
                        pass
                    else:
                        raise e

                try:
                    _currentdate = self.utils.add_hours(_currentdate+"0000", 1)
                    _currentdate = _currentdate[:10]
                except Exception, e:
                    raise e

    def read_keywords_range_summary_stat(self, _startdate, _enddate, _excludedate = []):
        if (len(_startdate) != 8 or len(_enddate) != 8):
            raise ValueError("Check _stardate or _enddate value. Required format => YYYYMMDD")

        if _startdate > _enddate:
            raise ValueError("_enddate is less than _startdate. check value")

        try:
            resultset = self.db.keywords_daily_stat.aggregate(
                    [
                        {"$match":
                            {"$and":
                                [
                                    {"_id.calldate": {"$gte":_startdate, "$lte": _enddate} },
                                    {"_id.calldate": {"$nin":_excludedate} }
                                ]
                            }
                        },
                        {"$project":
                            {
                                "keyword" : "$_id.keyword",
                                "count" : "$count"
                            }
                        },
                        {"$group": {
                            "_id" : "$keyword",
                            "count" : {"$sum" : "$count"}
                            }
                        },
                        {"$sort" : {"count":-1}}
                    ]
                )

            for r in resultset:
                yield r

        except Exception, e:
            raise e

    """
        parameters : 
           _targetdate : string(YYYYMMDD) 
        returns:
    """
    def read_keywords_daily_stat(self, _targetdate):
        if len(_targetdate) != 8:
            raise ValueError("Check _targetdate value. Required format => YYYYMMDD")

        try:
            resultset = self.db.keywords_daily_stat.find({"_id.calldate":_targetdate})
            for r in resultset:
                yield r
        except Exception, e:
            raise e

    """
        parameters : 
           _targetdatehour : string(YYYYMMDDHH24) 
        returns:
    """
    def read_keywords_hourly_stat(self, _targetdatehour):
        if len(_targetdatehour) != 10:
            raise ValueError("Check _targetdatehour value. Required format => YYYYMMDDHH24")

        try:
            resultset = self.db.keywords_hourly_stat.find({"_id.calldate":_targetdatehour})
            for r in resultset:
                yield r
        except Exception, e:
            raise e

    """
        parameters : 
           _targetdatehour : string(YYYYMMDDHH24) 
        returns:
    """
    def read_hourly_hot_keywords(self, _targetdatehour):
        if len(_targetdatehour) != 10:
            raise ValueError("Check _targetdatehour value. Required format => YYYYMMDDHH24")

        try:
            resultset = self.db.hourly_hot_keywords.find({"calldate":_targetdatehour}, {"_id":0})
            for r in resultset:
                yield r
        except Exception, e:
            raise e

    """
        parameters : 
           _targetdate : string(YYYYMMDD) 
        returns:
    """
    def read_daily_hot_keywords(self, _targetdate):
        if len(_targetdate) != 8:
            raise ValueError("Check _targetdate value. Required format => YYYYMMDD")

        try:
            resultset = self.db.daily_hot_keywords.find({"calldate":_targetdate}, {"_id":0})
            for r in resultset:
                yield r
        except Exception, e:
            raise e

    """
        parameters : 
           _targetdate : string(YYYYMMDD) 
    """
    def read_weekly_hot_keywords(self, _targetdate):
        if len(_targetdate) != 8:
            raise ValueError("Check _targetdate value. Required format => YYYYMMDD")

        try:
            resultset = self.db.weekly_hot_keywords.find({"calldate":_targetdate}, {"_id":0})
            for r in resultset:
                yield r
        except Exception, e:
            raise e

    """
        parameters : 
           _targetdate : string(YYYYMMDD) 
    """
    def read_monthly_hot_keywords(self, _targetmonth):
        if len(_targetmonth) != 6:
            raise ValueError("Check _targetmonth value. Required format => YYYYMM")

        try:
            resultset = self.db.monthly_hot_keywords.find({"calldate":_targetmonth}, {"_id":0})
            for r in resultset:
                yield r
        except Exception, e:
            raise e


class mariadb(object):
    def __init__(self, _dbname="msens_db", _host = "localhost", _port = 3306):
        self.db = pymysql.connect(host=_host, port=_port, db=_dbname, \
                user='msens', passwd='msens', charset='utf8')
        self.utils = utils()

    def __del__(self):
        self.db.close()
        del self.utils

    """
        Read Outbound agent script
    """
    def read_rule_script(self):
        with self.db.cursor() as cursor:
            cursor.execute("select id, assessment_stmt from wn_tmf_tbl_lsp")
            resultset = cursor.fetchall()
            return resultset   # tuple that contains tuples (( , ), ( , ), ....)
            #for result in resultset:
            #    result




if __name__=="__main__":
    # set parameter values
    # textid : use for query key
    # keywords : list of tuple(str, float)
    # collocations : list of tuple(tuple(str, str), float)

    textid = "123223123"
    keywords = [(u'정진각', 2.999323), (u'홍길동',1.5232) ]
    #collocations = [((u'정진각',u'홍길동'),3.233), ((u'진각',u'길동'),1.233) ]
    #collocations -> object format redefined. 
    #See collocation_extraction._convert_results_horizontally function parameter information
    rxtx="full"

    #db = mongodb("TA")
    #db.register_mining_results(textid, "full", keywords, collocations)
