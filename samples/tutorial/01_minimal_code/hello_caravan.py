from caravan import Server,Task

with Server.start():
    for i in range(10):
        Task.create("echo %d > out" % i)
