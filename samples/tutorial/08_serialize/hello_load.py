from caravan.tables import Tables
from caravan.task import Task
Tables.load("my_dump")         # data are loaded
for t in Task.all():
    print(t.to_dict())         # print Tasks

