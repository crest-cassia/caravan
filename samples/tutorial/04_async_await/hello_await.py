import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    for t in range(5):
        task = Task.create( "sleep %d" % (t%3+1) )
        Server.await_task( task )                         # this method blocks until the task is finished.
        print("step %d finished" % t, file=sys.stderr)    # show the progress to stderr
