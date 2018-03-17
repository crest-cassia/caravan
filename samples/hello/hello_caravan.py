import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    for i in range(10):
        Task.create("echo %d > out" % i)
