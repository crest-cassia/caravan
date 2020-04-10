from caravan import Tables,Task

Tables.load("dump.pickle")         # data are loaded
for t in Task.all():
    print(t.to_dict())         # print Tasks

