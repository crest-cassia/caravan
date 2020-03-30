import sys,os,math
from caravan.server import Server
from caravan.simulator import Simulator

this_dir = os.path.abspath(os.path.dirname(__file__))
sim = Simulator.create(f"python {this_dir}/mc_simulator.py > _output.json")

def err(ps):
    runs = ps.runs()
    r1 = [r.output() for r in runs]
    n = len(runs)
    avg = sum(r1) / n
    err = math.sqrt( sum([(r-avg)**2 for r in r1]) / ((n-1)*n) )
    return err

with Server.start():
    ps = sim.find_or_create_parameter_set({'mu':1.0,'sigma':2.0})
    ps.create_runs_upto(4)
    print("awaiting")
    Server.await_ps(ps)
    e = err(ps)
    while e > 0.2:
        print(f"error = {e}")
        ps.create_runs_upto(len(ps.runs()) + 4)  # add four runs
        print("awaiting")
        Server.await_ps(ps)
        e = err(ps)
    print(f"error = {e}")
