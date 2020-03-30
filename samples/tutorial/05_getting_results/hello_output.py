import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    t = Task.create("echo '[1.0,2.0,3.0]' > _output.json")
    Server.await_task(t)
    print(t.output())
