import sys
from caravan.server import Server
from caravan.task import Task
from caravan.server_stub import start_stub


def stub_sim(task):
    t = (task.id % 3) + 1
    return ((0.0, 1.0, 2.0), t)


with start_stub(stub_sim, num_proc=4):
    tasks = [Task.create("sleep %d" % (t % 3 + 1)) for t in range(5)]
    Server.await_all_tasks(tasks)  # this method blocks until all the tasks are finished
    print("all running tasks finished", file=sys.stderr)
    tasks = [Task.create("sleep %d" % (t % 3 + 1)) for t in range(5)]
