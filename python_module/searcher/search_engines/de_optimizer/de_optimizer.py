import sys
import random
from searcher.server import Server
from searcher.parameter_set import ParameterSet

class DE_Optimizer():

    def __init__( self, domains, n=None, f=0.8, cr=0.9, t_max=10, rand_seed=None, on_each_generation=None ):
        self.n = n
        if n is None:
            self.n = len(domains)*10
        self.f = f
        self.cr = cr
        self.random = random.Random()
        if rand_seed:
            self.random.seed( rand_seed )
        self.domains = domains
        self.t = 0
        self.t_max = t_max
        self.best_point = None
        self.best_f = float('inf')
        self.on_each_generation = on_each_generation

    def generate_initial_runs(self):
        self.population = []
        for i in range(self.n):
            point = [ self.random.random()*(d[1]-d[0])+d[0] for d in self.domains ]
            self.population.append( point )
        pss = [ self._find_or_create_ps_from_point(p) for p in self.population]

        self._generate_new_positions()
        new_pss = [ self._find_or_create_ps_from_point(p) for p in self.new_positions]
        Server.watch_all_ps(pss+new_pss, self._proceed)

    def _find_or_create_ps_from_point(self,point):
        ps = ParameterSet.create(point)
        ps.create_runs_upto(1)
        return ps

    def _generate_new_positions(self):
        self.new_positions = []
        for i in range(self.n):
            new_pos = self._generate_candidate(i)
            self.new_positions.append( new_pos )

    def _average_f(self):
        return sum( self.current_fs ) / len( self.current_fs )

    def _d(self,x):
        sys.stderr.write(repr(x)+"\n")

    def _proceed(self, pss):
        self.t += 1
        current_pss = pss[:self.n]
        new_pss = pss[self.n:]
        self.current_fs = [ ps.averaged_result()[0] for ps in current_pss ]

        new_fs = [ ps.averaged_result()[0] for ps in new_pss ]

        # selection
        for i in range(self.n):
            if new_fs[i] < self.current_fs[i]:
                self.population[i] = self.new_positions[i]
                if new_fs[i] < self.best_f:
                    self.best_point = self.new_positions[i][:]
                    self.best_f = new_fs[i]

        if not self.on_each_generation is None:
            self.on_each_generation()

        if self.t < self.t_max:
            pss = [ self._find_or_create_ps_from_point(p) for p in self.population]
            self._generate_new_positions()
            new_pss = [ self._find_or_create_ps_from_point(p) for p in self.new_positions]
            Server.watch_all_ps(pss+new_pss, self._proceed)

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
        r = self.random.randrange( dim )

        for d in range(dim):
            if d == r or self.random.random() < self.cr:
                new_pos[d] = self.population[a][d] + self.f * (self.population[b][d] - self.population[c][d])
        return new_pos

if __name__ == "__main__":
    from searcher.server_stub import ServerStub

    domains = [
        (-100, 100),
        (-100, 100)
    ]

    de = DE_Optimizer(domains, n=20, f=0.8, cr=0.9, t_max=20, rand_seed=1234)

    def print_logs():
        sys.stderr.write("t=%d  %s, %f, %f\n" % (de.t, repr(de.best_point), de.best_f, de._average_f()))

    def map_point_to_result(point, seed):
        return [(point[0] - 1.0) ** 2 + (point[1] - 2.0) ** 2]

    def map_point_to_duration(point, seed):
        return 1.0

    de.on_each_generation = print_logs
    de.generate_initial_runs()
    ServerStub.loop(map_point_to_result, map_point_to_duration)

