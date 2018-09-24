import sys, random
from caravan.server import Server
from caravan.task import Task
from caravan.tables import Tables

"""
sleep for a duration drawn from a power-law distribution p(x)=Cx^{-alpha}, where C is a normalization constant
The lower and upper bounds of the duration is [duration_min, duration_max].
"""


class PowerLawSleep:
    def __init__(self, num_jobs, init_n, alpha, duration_min, duration_max):
        self.num_jobs = num_jobs
        self.init_n = init_n
        self.alpha = alpha
        self.sleep_range = (duration_min, duration_max)
        self.n = self.init_n
        random.seed(1234)

    def _t(self):
        r = random.random()
        b = self.sleep_range[1]
        a = self.sleep_range[0]
        alpha = self.alpha
        t = (r * (b ** (-alpha + 1) - a ** (-alpha + 1)) + a ** (-alpha + 1)) ** (1.0 / (-alpha + 1))
        return t

    def _create_one(self):
        t = self._t()
        task = Task.create("sleep {t}".format(t=t))
        if self.n < self.num_jobs:
            task.add_callback(lambda t: self._create_one() )
            self.n += 1

    def create_initial_runs(self):
        for i in range(self.init_n):
            self._create_one()


if len(sys.argv) != 6 and len(sys.argv) != 7:
    sys.stderr.write(str(sys.argv))
    sys.stderr.write("invalid number of argument\n")
    args = ["num_jobs", "init_n", "alpha", "min", "max", "[num_stub_cpus]"]
    sys.stderr.write("Usage: python %s %s\n" % (__file__, " ".join(args)))
    raise RuntimeError("invalid number of arguments")


if len(sys.argv) == 6:
    with Server.start():
        se = PowerLawSleep(int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5]))
        se.create_initial_runs()
else:
    from caravan.server_stub import start_stub
    def stub_sim(t):
        t = float(t.command.split()[1])
        results = (1.0,)
        return results, t
    with start_stub(stub_sim, num_proc=int(sys.argv[6])):
        se = PowerLawSleep(int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5]))
        se.create_initial_runs()

if all([t.is_finished() for t in Task.all()]):
    sys.stderr.write("DONE\n")
else:
    Tables.dump("table.pickle")
