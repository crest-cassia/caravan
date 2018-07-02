import sys
from caravan.server import Server
from caravan.task import Task
from caravan.tables import Tables

def eprint(s):
    print(s, file=sys.stderr, flush=True)

with Server.start():
    tasks = []
    for i in range(10):
        t = Task.create("sleep %d; echo %d > out" % (i%3,i))
        tasks.append(t)
        eprint("task %i is created." % i)
    Server.await_all_tasks(tasks)
    Tables.dump('my_dump')

