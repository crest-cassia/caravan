import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    for i in range(10):
        task = Task.create("sleep %d" % (i%3+1))
        task.add_callback(lambda t, i=i: Task.create("sleep %d" % (i%3+1)))

