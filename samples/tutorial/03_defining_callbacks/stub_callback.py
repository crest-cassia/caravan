import sys
from caravan.server import Server
from caravan.task import Task
from caravan.server_stub import start_stub


def stub_sim(task):
    i = task.id
    dt = i % 3 + 1
    return ((), dt)


with start_stub(stub_sim, num_proc=16):
    for i in range(10):
        task = Task.create("sleep %d" % (i % 3 + 1))
        task.add_callback(lambda t, i=i: Task.create("sleep %d" % (i % 3 + 1)))
