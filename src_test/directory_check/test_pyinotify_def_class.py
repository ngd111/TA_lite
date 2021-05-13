import pyinotify

wm = pyinotify.WatchManager()

def Run():

    mask = pyinotify.IN_DELETE | pyinotify.IN_CLOSE_WRITE | pyinotify.IN_MOVED_TO
    wdd = wm.add_watch('/home/winddori/dev/TA_lite/data/msens', mask, rec=True)

    class EventHandler(pyinotify.ProcessEvent):
        def process_IN_CREATE(self, event):
            print "Creating:", event.pathname
        
        def process_IN_DELETE(self, event):
            print "Removing:", event.pathname

        def process_IN_CLOSE_WRITE(self, event):
            print "File was close write:", event.pathname

    handler = EventHandler()
    #notifier = pyinotify.Notifier(wm, handler, timeout=5)
    notifier = pyinotify.Notifier(wm, handler)

    notifier.loop()


Run()
