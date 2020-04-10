from caravan import Server,Task,Tables

with Server.start():
    for i in range(10):
        t = Task.create(f"sleep {1+i%3}; echo {i} > _output.json")
        print(f"task {i} is created.")
Tables.dump('dump.pickle')

