import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    tasks = [ Task.create( "sleep %d" % (t%3+1) ) for t in range(5) ]
    Server.await_all_tasks( tasks )                   # this method blocks until all the tasks are finished
    print("all running tasks finished", file=sys.stderr)
    tasks = [ Task.create( "sleep %d" % (t%3+1) ) for t in range(5) ]

