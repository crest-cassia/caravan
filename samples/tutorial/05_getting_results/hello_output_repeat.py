import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    i = 0
    t = Task.create(f"echo {i} > _output.json")
    while True:
        print(f"awaiting Task({i})")
        Server.await_task(t)
        if t.output() < 3:
            i += 1
            t = Task.create(f"echo {i} > _output.json")
        else:
            break
