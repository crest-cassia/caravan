import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    for i in range(40):
        Task.create("echo %d && sleep %d" % (i, i % 3 + 1))
