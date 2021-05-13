from apscheduler.schedulers.blocking import BlockingScheduler

def jobf():
    print "HWorld"

def jobf2():
    print "World Wind"

sched = BlockingScheduler()


#sched.add_job(jobf, 'cron', hour='0-23')
#sched.add_job(jobf, 'interval', seconds=3)
#sched.add_job(jobf2, 'interval', seconds=5)
sched.add_job(jobf2, 'cron', minute=1)    # every hour 1 minute run, 00:01, 01:01 ...
#sched.add_job(jobf2, 'cron', minute='0-59,1')    # every hour 1 minute run, 00:01, 01:01 ...

sched.start()
