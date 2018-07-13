import sys
from caravan.server import Server
from caravan.tables import Tables
from caravan.task import Task

def eprint(s):
    print(s, file=sys.stderr, flush=True)

Tables.load("my_dump")         # data are loaded
for t in Task.all():
    eprint(t.to_dict())         # print Tasks

with Server.start():  # restart scheduler
    pass

eprint("second execution done")
for t in Task.all():
    eprint(t.to_dict())         # print Tasks

