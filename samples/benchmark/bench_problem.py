import sys,random,pickle
from caravan.server import Server
from caravan.parameter_set import ParameterSet
from caravan.tables import Tables

class BenchSearcher:

    def __init__(self,num_static_jobs,num_dynamic_jobs,job_gen_prob,num_jobs_per_gen,sleep_mu,sleep_sigma):
        self.num_static_jobs = num_static_jobs
        self.num_dynamic_jobs = num_dynamic_jobs
        self.job_gen_prob = job_gen_prob
        self.num_jobs_per_gen = num_jobs_per_gen
        self.sleep_range = ( sleep_mu - sleep_sigma, sleep_mu + sleep_sigma )
        random.seed(1234)
        self.ps_count = 0
        self.num_running = 0
        self.num_todo = self.num_static_jobs + self.num_dynamic_jobs

    def _create_one(self):
        t = random.uniform( self.sleep_range[0], self.sleep_range[1] )
        ps = ParameterSet.find_or_create(t)
        self.ps_count += 1
        self.num_running += 1
        self.num_todo -= 1
        ps.create_runs_upto(1)
        Server.watch_ps( ps, self.on_ps_finished )

    def create_initial_runs(self):
        for i in range(self.num_static_jobs):
            self._create_one()

    def restart(self):
        unfinished = [ps for ps in ParameterSet.all() if not ps.is_finished()]
        self.ps_count = len(ParameterSet.all())
        self.num_running = len(unfinished)
        self.num_todo -= self.ps_count
        for ps in unfinished:
            Server.watch_ps(ps, se.on_ps_finished)

    def on_ps_finished(self, ps):
        self.num_running -= 1
        if random.random() < self.job_gen_prob or self.num_running == 0:
            num_tasks = self.num_jobs_per_gen if self.num_jobs_per_gen < self.num_todo else self.num_todo
            for i in range(num_tasks):
                self._create_one()

if len(sys.argv) != 7 and len(sys.argv) != 8:
    sys.stderr.write(str(sys.argv))
    sys.stderr.write("invalid number of argument\n")
    args = ["num_static_jobs", "num_dynamic_jobs", "job_gen_prob",
            "num_jobs_per_gen", "sleep_mu", "sleep_sigma", "[table.pickle]"]
    sys.stderr.write("Usage: python %s %s\n" % (__file__, " ".join(args)))
    raise RuntimeError("invalid number of arguments")

num_static_jobs = int(sys.argv[1])
num_dynamic_jobs = int(sys.argv[2])
job_gen_prob = float(sys.argv[3])
num_jobs_per_gen = int(sys.argv[4])
sleep_mu = float(sys.argv[5])
sleep_sigma = float(sys.argv[6])


def map_params_to_cmd(t, seed):
    return "sleep %f" % t

ParameterSet.set_command_func(map_params_to_cmd)
with Server.start(redirect_stdout=True):
    se = BenchSearcher(num_static_jobs,num_dynamic_jobs,job_gen_prob,num_jobs_per_gen,sleep_mu,sleep_sigma)
    if len(sys.argv) == 7:
        print("starting")
        se.create_initial_runs()
    else:
        print("restarting")
        Tables.load(sys.argv[7])
        se.restart()

if all([ps.is_finished() for ps in ParameterSet.all()]):
    sys.stderr.write("DONE\n")
else:
    sys.stderr.write("There are unfinished tasks. Writing data to table.pickle\n")
    Tables.dump("table.pickle")

