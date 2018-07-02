import sys,os
from caravan.server import Server
from caravan.parameter_set import ParameterSet


# define a function which receives a tuple of parameters and a random-number seed, and returns the command to be executed
def make_cmd(params, seed):
    args = " ".join([str(x) for x in params])
    this_dir = os.path.abspath(os.path.dirname(__file__))
    return "python %s/mc_simulator.py %s %d > _results.txt" % (this_dir, args, seed)


ParameterSet.set_command_func(
    make_cmd)  # set `make_cmd`. When runs are created, `make_cmd` is called when Runs are created.

with Server.start():
    ps = ParameterSet.find_or_create(1.0, 2.0)  # create a ParameterSet whose parameters are (1.0,2.0).
    ps.create_runs_upto(10)  # create ten Runs. In the background, `make_cmd` is called to generate actual commands.
    Server.await_ps(ps)  # wait until all the Runs of this ParameterSet finishes
    x = ps.average_results()  # results are averaged over the Runs
    print("average: %f" % x, file=sys.stderr, flush=True)
    for r in ps.runs():
        print(r.results, file=sys.stderr, flush=True)  # showing results of each Run
