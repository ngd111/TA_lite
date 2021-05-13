import pyinotify
import Queue
import time
import signal
import sys

class dummy:
    def __init__(self):
        self.exit_flag = False

    def set_flag(self, _flag):
        self.exit_flag = _flag

    def get_flag(self):
        return self.exit_flag

q = Queue.Queue()

fobj = dummy()

wm = pyinotify.WatchManager()
mask = pyinotify.IN_DELETE  | pyinotify.IN_MOVED_TO | pyinotify.IN_CLOSE_WRITE

def signal_handler(signal, frame):
    print('Ctrl+C!')
    fobj.set_flag(True)
    #sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

class EventHandler(pyinotify.ProcessEvent):
    def process_IN_CLOSE_WRITE(self, event):
        print "Close write:", event.pathname
        q.put(event.pathname)

    def process_IN_MOVED_TO(self, event):
        print "Moved to :", event.pathname
        q.put(event.pathname)

notifier = pyinotify.ThreadedNotifier(wm, EventHandler())
notifier.start()

wdd = wm.add_watch('/home/winddori/dev/TA_lite/data/msens', mask, rec=True)
print('~Start!!!!!!!!!!!!!!!!!!!')

while(True!=False):
    while not q.empty():
        print ('read queue %s' % q.get())
        q.task_done()
    time.sleep(1)
    if (fobj.get_flag() == True):
        q.join()
        break

wm.rm_watch(wdd.values())
notifier.stop()

sys.exit(0)
