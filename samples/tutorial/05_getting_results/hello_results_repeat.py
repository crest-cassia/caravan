import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    i = 0
    t = Task.create("echo %d > _results.txt" % i)
    while True:
        print("awaiting Task(%d)" % i, file=sys.stderr, flush=True)
        Server.await_task(t)
        if t.results[0] < 3:
            i += 1
            t = Task.create("echo %d > _results.txt" % i)
        else:
            break
