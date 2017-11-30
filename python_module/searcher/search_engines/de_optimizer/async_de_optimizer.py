import sys
import random
from searcher.server import Server
from searcher.parameter_set import ParameterSet


class Domain():
    def __init__(self, minimum, maximum):
        self.min = minimum
        self.max = maximum
        assert self.min < self.max

    def scale(self, r):
        """
        give [0,1] value and returns the scaled value
        """
        return r * (self.max - self.min) + self.min

class DE_Optimizer():

    def __init__( self, map_func, domains, n=None, f=0.8, cr=0.9, rand_seed=None ):
        self.n = (n or len(domains)*10)
        self.f = f
        self.cr = cr
        self.random = random.Random()
        if rand_seed:
            self.random.seed( rand_seed )
        self.domains = [ Domain(d[0],d[1]) for d in domains ]
        self.map_func = map_func
        self.t = 0
        self.best_point = None
        self.best_f = float('inf')

        self.generate_initial_points()

    def generate_initial_points(self):
        self.population = []
        for i in range(self.n):
            point = [ d.scale( self.random.random() ) for d in self.domains ]
            self.population.append( point )
        self.current_fs = self.map_func( self.population )

    def average_f(self):
        return sum( self.current_fs ) / len( self.current_fs )

    def proceed(self):
        new_positions = []
        for i in range(self.n):
            new_pos = self._generate_candidate(i)
            new_positions.append( new_pos )

        new_fs = self.map_func( new_positions )

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

        new_pos = self.population[i].copy()

        dim = len(self.domains)
        r = self.random.randrange( dim )

        for d in range(dim):
            if d == r or self.random.random() < self.cr:
                new_pos[d] = self.population[a][d] + self.f * (self.population[b][d] - self.population[c][d])
        return new_pos


if __name__ == "__main__":
    from searcher.server_stub import ServerStub

    def run_optimization():
        print("running optimization")
        domains = [
            (-100, 100),
            (-100, 100)
        ]
        def _find_or_create_ps_from_point(point):
            int_point = [ round(x) for x in point ]
            ps = ParameterSet.find_or_create(int_point)
            ps.create_runs_upto(1)
            return ps

        def map_agents(agents):
            parameter_sets = [_find_or_create_ps_from_point(point) for point in agents]
            ServerStub.await_all_ps(parameter_sets)
            results = [ps.averaged_result()[0] for ps in parameter_sets]
            return results
        opt = DE_Optimizer(map_agents, domains, n=20, f=0.8, cr=0.9, rand_seed=1234)

        for t in range(20):
            opt.proceed()
            sys.stderr.write("t=%d  %s, %f, %f\n" % (opt.t, repr(opt.best_point), opt.best_f, opt.average_f()))

    def map_point_to_result(point, seed):
        return [(point[0] - 1.0) ** 2 + (point[1] - 2.0) ** 2]

    def map_point_to_duration(point, seed):
        return 1.0

    Server.async(run_optimization)
    ServerStub.loop(map_point_to_result, map_point_to_duration)

