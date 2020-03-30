import sys
from caravan.server import Server
from caravan.task import Task

with Server.start():
    for i in range(6):
        task = Task.create(f"sleep {1+i%3}")
        task.add_callback(lambda i=i: Task.create(f"sleep {1+i%3}"))
