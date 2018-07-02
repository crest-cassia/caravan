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
    return np.all(errs < 0.5)


def do_until_convergence(params):
    ps = ParameterSet.find_or_create(params)
    ps.create_runs_upto(4)
    Server.await_ps(ps)
    while not converged(ps):
        eprint("results for {params} is not converged".format(**locals()))
        ps.create_runs_upto(len(ps.runs()) + 4)  # add four runs
        Server.await_ps(ps)
    eprint("converged results : {0}, params {1}".format(ps.average_results(), params))


with Server.start():
    for p1 in [1.0, 1.5, 2.0, 2.5]:
        for p2 in [2.0, 3.0]:
            Server.async(lambda _param=(p1, p2): do_until_convergence(_param))

for ps in ParameterSet.all():
    assert( converged(ps) )
    eprint("ps %s converged." % str(ps.params))

