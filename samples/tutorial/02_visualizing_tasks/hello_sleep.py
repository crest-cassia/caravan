import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    for i in range(20):
        Task.create(f"sleep {1+i%3}")
