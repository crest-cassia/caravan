import sys,random,os
from caravan.server import Server
from caravan.simulator import Simulator


class Domain:
    def __init__(self, minimum, maximum):
        self.min = minimum
        self.max = maximum
        assert self.min < self.max

    def scale(self, r):
        """
        give [0,1] value and returns the scaled value
        """
        return r * (self.max - self.min) + self.min


class DE_Optimizer:
    def __init__(self, map_func, domains, n=None, f=0.8, cr=0.9, rand_seed=None):
        self.n = (n or len(domains) * 10)
        self.f = f
        self.cr = cr
        self.random = random.Random()
        if rand_seed:
            self.random.seed(rand_seed)
        self.domains = [Domain(d[0], d[1]) for d in domains]
        self.map_func = map_func
        self.t = 0
        self.best_point = None
        self.best_f = float('inf')

        self.generate_initial_points()

    def generate_initial_points(self):
        self.population = []
        for i in range(self.n):
            point = [d.scale(self.random.random()) for d in self.domains]
            self.population.append(point)
        self.current_fs = self.map_func(self.population)

    def average_f(self):
        return sum(self.current_fs) / len(self.current_fs)

    def proceed(self):
        new_positions = []
        for i in range(self.n):
            new_pos = self._generate_candidate(i)
            new_positions.append(new_pos)

        new_fs = self.map_func(new_positions)

        # selection
        for i in range(self.n):
            if new_fs[i] < self.current_fs[i]:
                self.population[i] = new_positions[i]
                self.current_fs[i] = new_fs[i]
                if new_fs[i] < self.best_f:
                    self.best_point = new_positions[i]
                    self.best_f = new_fs[i]

        self.t += 1

    def _generate_candidate(self, i):
        """
        generate a candidate for population[i]
        based on DE/rand/1/binom algorithm
        """

        a = i
        while a == i:
            a = self.random.randrange(self.n)
        b = i
        while b == i or b == a:
            b = self.random.randrange(self.n)
        c = i
        while c == i or c == a or c == b:
            c = self.random.randrange(self.n)

        new_pos = self.population[i][:]

        dim = len(self.domains)
        r = self.random.randrange(dim)

        for d in range(dim):
            if d == r or self.random.random() < self.cr:
                new_pos[d] = self.population[a][d] + self.f * (self.population[b][d] - self.population[c][d])
        return new_pos


if len(sys.argv) != 5:
    sys.stderr.write("invalid number of arguments\n")
    sys.stderr.write("[Usage] python -u %s <n> <f> <cr> <tmax>\n" % __file__)
    raise Exception("invalid number of arguments")


def run_optimization(sim, n, f, cr, tmax):
    domains = [
        (-1000, 1000),
        (-1000, 1000)
    ]

    def map_agents(agents):
        parameter_sets = [sim.find_or_create_parameter_set({'x':point[0],'y':point[1]}) for point in agents]
        for ps in parameter_sets:
            ps.create_runs_upto(1)
        Server.await_all_ps(parameter_sets)
        results = [ps.outputs()[0]['f'] for ps in parameter_sets]
        return results

    de = DE_Optimizer(map_agents, domains, n=n, f=f, cr=cr, rand_seed=1234)

    with open("opt_log.txt", "w") as fout:
        fout.write("### t [best_point] best_f average_f\n")
        for t in range(tmax):
            de.proceed()
            fout.write("%d %s %f %f\n" % (de.t, repr(de.best_point), de.best_f, de.average_f()))

sim = Simulator.create(f"python {os.path.dirname(__file__)}/my_sim.py")

with Server.start():
    n = int(sys.argv[1])
    f = float(sys.argv[2])
    cr = float(sys.argv[3])
    tmax = int(sys.argv[4])
    print("optimization parameters are n=%d, f=%f, cr=%f, tmax=%d\n" % (n, f, cr, tmax))
    run_optimization(sim, n, f, cr, tmax)
