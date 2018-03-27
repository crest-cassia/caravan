import sys
from caravan.server import Server
from caravan.task import Task


def run_sequential_tasks(n):
    for t in range(5):
        task = Task.create("sleep %d" % ((t + n) % 3 + 1))
        Server.await_task(task)  # this method blocks until the task is finished.
        print("step %d of %d finished" % (t, n), file=sys.stderr)  # show the progress to stderr


with Server.start():
    for n in range(3):
        Server.async(lambda _n=n: run_sequential_tasks(_n))
