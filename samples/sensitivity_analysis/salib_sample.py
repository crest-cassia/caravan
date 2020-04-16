import sys,random,os
from caravan import Server,Task,Tables,StubServer
from SALib.sample import saltelli


problem = {
    'num_vars': 3,
    'names': ['x1', 'x2', 'x3'],
    'bounds': [[-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359]]
}

cmd = f"python {os.path.dirname(__file__)}/ishigami.py"

with Server.start():
    param_values = saltelli.sample(problem, 1000, calc_second_order=False)
    for param in param_values:
        Task.create(cmd, {"x1":param[0],"x2":param[1],"x3":param[2]})

Tables.dump('tasks.pickle')
