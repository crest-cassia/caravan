import sys, random
from caravan.server import Server
from caravan.task import Task
from caravan.tables import Tables


class BenchSearcher:
    def __init__(self, num_static_jobs, num_dynamic_jobs, job_gen_prob, num_jobs_per_gen, sleep_mu, sleep_sigma):
        self.num_static_jobs = num_static_jobs
        self.num_dynamic_jobs = num_dynamic_jobs
        self.job_gen_prob = job_gen_prob
        self.num_jobs_per_gen = num_jobs_per_gen
        self.sleep_range = (sleep_mu - sleep_sigma, sleep_mu + sleep_sigma)
        random.seed(1234)
        self.ps_count = 0
        self.num_running = 0
        self.num_todo = self.num_static_jobs + self.num_dynamic_jobs

    def _create_one(self):
        t = random.uniform(self.sleep_range[0], self.sleep_range[1])
        task = Task.create("sleep {t}; echo '{{\"t\": {t}}}' > _output.json".format(t=t))
        self.ps_count += 1
        self.num_running += 1
        self.num_todo -= 1
        task.add_callback(self._on_task_finished)

    def create_initial_runs(self):
        for i in range(self.num_static_jobs):
            self._create_one()

    def restart(self):
        unfinished = [t for t in Task.all() if not t.is_finished()]
        self.ps_count = len(Task.all())
        self.num_running = len(unfinished)
        self.num_todo -= self.ps_count
        for t in unfinished:
            t.add_callback(self._on_task_finished)

    def _on_task_finished(self, task):
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

with Server.start(redirect_stdout=True):
    se = BenchSearcher(num_static_jobs, num_dynamic_jobs, job_gen_prob, num_jobs_per_gen, sleep_mu, sleep_sigma)
    if len(sys.argv) == 7:
        print("starting", file=sys.stderr, flush=True)
        se.create_initial_runs()
    else:
        print("restarting", file=sys.stderr, flush=True)
        Tables.load(sys.argv[7])
        se.restart()

if all([t.is_finished() for t in Task.all()]):
    sys.stderr.write("DONE\n")
else:
    sys.stderr.write("There are unfinished tasks. Writing data to table.pickle\n")
    Tables.dump("table.pickle")
