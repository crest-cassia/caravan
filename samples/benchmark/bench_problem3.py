import sys, random
from caravan.server import Server
from caravan.parameter_set import ParameterSet
from caravan.tables import Tables

"""
sleep for a duration drawn from a power-law distribution p(x)=Cx^{-alpha}, where C is a normalization constant
The lower and upper bounds of the duration is [duration_min, duration_max].
"""


class PowerLawSleep:
    def __init__(self, num_jobs, alpha, duration_min, duration_max):
        self.num_jobs = num_jobs
        self.alpha = alpha
        self.sleep_range = (duration_min, duration_max)
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
        ps = ParameterSet.create(t)
        ps.create_runs_upto(1)

    def create_initial_runs(self):
        for i in range(self.num_jobs):
            self._create_one()


if len(sys.argv) != 5 and len(sys.argv) != 6:
    sys.stderr.write(str(sys.argv))
    sys.stderr.write("invalid number of argument\n")
    args = ["num_jobs", "alpha", "min", "max", "[table.dump]"]
    sys.stderr.write("Usage: python %s %s\n" % (__file__, " ".join(args)))
    raise RuntimeError("invalid number of arguments")

se = PowerLawSleep(int(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]))


def map_params_to_cmd(t, seed):
    return "sleep %f" % t


if len(sys.argv) == 5:
    se.create_initial_runs()
else:
    Tables.load(sys.argv[5])

Server.loop(map_params_to_cmd)

if all([ps.is_finished() for ps in ParameterSet.all()]):
    sys.stderr.write("DONE\n")
else:
    sys.stderr.write("There are unfinished tasks. Writing data to table.msgpack\n")
    Tables.pack("table.msgpack")
