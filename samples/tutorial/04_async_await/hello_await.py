from caravan import Server,Task

with Server.start():
    for i in range(5):
        task = Task.create(f"sleep {1+i%3}")
        Server.await_task(task)  # this method blocks until the task is finished.
        print(f"step {i} finished. rc: {task.rc()}, rank: {task.rank()}, {task.start_at()}-{task.finish_at()}") # show info of completed task
