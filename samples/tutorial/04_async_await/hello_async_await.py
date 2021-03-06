import functools
from caravan import Server,Task

def run_sequential_tasks(n):
    for i in range(4):
        task = Task.create(f"sleep {1+i%3}")
        Server.await_task(task)  # this method blocks until the task is complete.
        print(f"step {i} of {n} finished")  # show the progress

with Server.start():
    for n in range(3):
        Server.do_async( functools.partial(run_sequential_tasks,n) )
