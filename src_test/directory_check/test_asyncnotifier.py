import asyncore
import pyinotify

wm = pyinotify.WatchManager()
mask = pyinotify.IN_DELETE  | pyinotify.IN_MOVED_TO | pyinotify.IN_CLOSE_WRITE

class EventHandler(pyinotify.ProcessEvent):
    def process_IN_CLOSE_WRITE(self, event):
        print "Close write:", event.pathname

    def process_IN_MOVED_TO(self, event):
        print "Moved to :", event.pathname

notifier = pyinotify.AsyncNotifier(wm, EventHandler())
wdd = wm.add_watch('/home/winddori/dev/TA_lite/data', mask, rec=True)

asyncore.loop()
