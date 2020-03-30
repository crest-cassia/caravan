from caravan.task import Task
from caravan.stub_server import StubServer


def stub_sim(task):
    results = (task.id()+3, task.id()+10)
    elapsed = 1
    return results, elapsed

with StubServer.start(stub_sim, num_proc=4):
    for i in range(10):
        Task.create(f"echo {i}")
