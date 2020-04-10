from caravan import Server,Tables,Task

Tables.load("dump.pickle")         # data are loaded
Task.reset_cancelled()

for t in Task.all():
    print(t.to_dict())         # print Tasks

with Server.start():  # restart scheduler
    pass

print("second execution done")
for t in Task.all():
    print(t.to_dict())         # print Tasks

