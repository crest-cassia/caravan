import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    for i in range(6):
        task = Task.create("sleep %d" % (i % 3 + 1))
        task.add_callback(lambda t, _i=i: Task.create("sleep %d" % (_i % 3 + 1)))
