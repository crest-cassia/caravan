import sys,random
from searcher.server import Server
from searcher.parameter_set import ParameterSet

if len(sys.argv) != 7:
    sys.stderr.write(str(sys.argv))
    sys.stderr.write("invalid number of argument\n")
    args = ["num_max_job", "num_min_job", "iteration",
            "num_jobs_per_gen", "sleep_mu", "sleep_sigma"]
    sys.stderr.write("Usage: python %s %s\n" % (__file__, " ".join(args)))
    raise RuntimeError("invalid number of arguments")

class BenchSearcher2:

    def __init__(self, w):
        self.num_max_job = int(sys.argv[1])
        self.num_min_job = int(sys.argv[2])
        self.iteration = int(sys.argv[3])
        self.num_jobs_per_gen = int(sys.argv[4])
        sleep_mu = float(sys.argv[5])
        sleep_sigma = float(sys.argv[6])
        self.sleep_range = ( sleep_mu - sleep_sigma, sleep_mu + sleep_sigma )
        random.seed(1234)
        self.ps_count = 0
        self.num_running = 0
        self.w = w

    def _create_one(self):
        t = random.uniform( self.sleep_range[0], self.sleep_range[1] )
        point = (int(t*10), self.ps_count)
        ps = ParameterSet.find_or_create( point )
        self.ps_count += 1
        self.num_running += 1
        ps.create_runs_upto(1)
        self.w.watch_ps( ps, self.on_ps_finished )

    def create_initial_runs(self):
        for i in range(self.num_max_job):
            self._create_one()

    def on_ps_finished(self, ps):
        self.num_running -= 1
        if self.num_running == self.num_min_job and self.iteration > 0:
            for i in range(self.num_jobs_per_gen):
                self._create_one()
            self.iteration -= 1

def map_point_to_cmd(point, seed):
    t = point[0] * 0.1
    return "sleep %f" % t

w = Server( map_point_to_cmd )
se = BenchSearcher2(w)
se.create_initial_runs()
w.loop()
sys.stderr.write("DONE\n")

