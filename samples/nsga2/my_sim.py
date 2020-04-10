import json
import numpy as np
from deap import benchmarks

with open("_input.json") as fin:
    p = json.load(fin)
    y1,y2 = benchmarks.zdt1( np.array(p['x']) )
    with(open("_output.json",'w')) as fout:
        json.dump({'y1':y1, 'y2':y2}, fout)

