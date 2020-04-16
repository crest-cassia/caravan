import sys
from caravan import Tables,Task
from SALib.analyze import sobol
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


if len(sys.argv) != 2:
    print("Usage: python analyze.py tasks.pickle")
    raise Exception("invalid usage")

problem = {
    'num_vars': 3,
    'names': ['x1', 'x2', 'x3'],
    'bounds': [[-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359]]
}

Tables.load(sys.argv[1])
ys = []
for t in Task.all():
    assert t.rc() == 0
    ys.append(t.output()['y'])

print(f"length of ys: {len(ys)}")

# plot first-order sensitivity indices
Si = sobol.analyze(problem, np.array(ys), calc_second_order=False)
x = np.arange( problem['num_vars'] )
plt.xticks(x, problem['names'])
plt.ylabel('Si')
plt.bar(x, Si['S1'], yerr=Si['S1_conf'])
plt.savefig('S1.png')
plt.clf()

# plot total-order sensitivity indices
x = np.arange( problem['num_vars'] )
plt.xticks(x, problem['names'])
plt.ylabel('ST')
plt.bar(x, Si['ST'], yerr=Si['ST_conf'])
plt.savefig('St.png')
plt.clf()

