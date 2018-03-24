from caravan.task import Task
from caravan.server_stub import start_stub


def stub_sim(task):
    results = (task.id + 3, task.id + 10)
    elapsed = 1
    return results, elapsed

with start_stub(stub_sim, num_proc=4):
    for i in range(10):
        Task.create("echo %d > out" % i)

