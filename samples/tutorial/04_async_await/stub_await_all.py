import sys
from caravan.server import Server
from caravan.task import Task
from caravan.server_stub import start_stub

def stub_sim(task):
    t = 1+task.id()%3
    return ({}, t)

with start_stub(stub_sim, num_proc=4):
    tasks1 = [Task.create(f"sleep {1+i%3}") for i in range(5)]
    Server.await_all_tasks(tasks1)  # this method blocks until all the tasks are finished
    print("all running tasks are complete!")
    for t in tasks1:
        print(f"task ID:{t.id()}, rc:{t.rc()}, rank:{t.rank()}, {t.start_at()}-{t.finish_at()}")
