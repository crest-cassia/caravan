import sys,os
from caravan.server import Server
from caravan.simulator import Simulator

this_dir = os.path.abspath(os.path.dirname(__file__))
sim = Simulator.create(f"python {this_dir}/mc_simulator.py > _output.json")

with Server.start():
    ps = sim.find_or_create_parameter_set({'mu':1.0,'sigma':2.0}) # create a ParameterSet whose parameters are (mu=1.0,sigma=2.0).
    ps.create_runs_upto(10)  # create ten Runs. In the background, `make_cmd` is called to generate actual commands.
    Server.await_ps(ps)  # wait until all the Runs of this ParameterSet finishes
    avg = sum([r.output() for r in ps.runs()])/len(ps.runs())  # results are averaged over the Runs
    print(f"average: {avg}")
    for r in ps.runs():
        print(f"id: {r.id()}, output: {r.output()}")  # showing results of each Run
