import os,math
from caravan import Server,Simulator,StubServer

this_dir = os.path.abspath(os.path.dirname(__file__))
sim = Simulator.create(f"python {this_dir}/mc_simulator.py > _output.json")

def err(ps):
    runs = ps.runs()
    r1 = [r.output() for r in runs]
    n = len(runs)
    avg = sum(r1) / n
    err = math.sqrt( sum([(r-avg)**2 for r in r1]) / ((n-1)*n) )
    return err

def do_until_convergence(params):
    ps = sim.find_or_create_parameter_set(params)
    ps.create_runs_upto(4)
    Server.await_ps(ps)
    e = err(ps)
    while e > 0.2:
        print(f"results for {params} is not converged")
        ps.create_runs_upto(len(ps.runs()) + 4)  # add four runs
        Server.await_ps(ps)
        e = err(ps)
    print(f"converged results for {params}, error = {e}")

import random
random.seed(1234)
def stub_sim(task):
    output = 3+10*random.random()
    elapsed = 1
    return output, elapsed

with StubServer.start(stub_sim, num_proc=4):
    for p1 in [1.0, 1.5, 2.0, 2.5]:
        for p2 in [0.5, 1.0]:
            Server.do_async(lambda param={'mu':p1,'sigma':p2}: do_until_convergence(param))

