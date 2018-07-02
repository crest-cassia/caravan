import sys,os
from caravan.server import Server
from caravan.parameter_set import ParameterSet


def make_cmd(params, seed):
    args = " ".join([str(x) for x in params])
    this_dir = os.path.abspath(os.path.dirname(__file__))
    return "python %s/mc_simulator.py %s %d > _results.txt" % (this_dir, args, seed)


ParameterSet.set_command_func(make_cmd)

import math
import numpy as np


def eprint(s):
    print(s, file=sys.stderr, flush=True)


def converged(ps):
    runs = ps.runs()
    r1 = [r.results for r in runs]
    errs = np.std(r1, axis=0, ddof=1) / math.sqrt(len(runs))
    eprint(errs)
    return np.all(errs < 0.2)


with Server.start():
    ps = ParameterSet.find_or_create(1.0, 2.0)
    ps.create_runs_upto(4)
    eprint("awaiting")
    Server.await_ps(ps)
    while not converged(ps):
        ps.create_runs_upto(len(ps.runs()) + 4)  # add four runs
        eprint("awaiting")
        Server.await_ps(ps)
    print(ps.average_results(), file=sys.stderr)
