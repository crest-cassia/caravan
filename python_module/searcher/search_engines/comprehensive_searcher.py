import itertools
from searcher.parameter_set import ParameterSet
from searcher.run import Run

class ComprehensiveSearcher:

    def __init__(self, ranges, num_runs=1):
        self.ranges = ranges
        self.num_runs = num_runs

    def create_initial_runs(self):
        for point in itertools.product( *self.ranges ):
            ps = ParameterSet.create(point)
            ps.create_runs_upto(self.num_runs)

if __name__ == "__main__":
    from searcher.server_stub import ServerStub

    ranges = [
        range(-2, 3),
        range(0, 2)
    ]

    s = ComprehensiveSearcher(ranges, num_runs=2)

    def map_params_to_result(params, seed):
        return [params[0]**2 + params[1]**2]

    def map_params_to_duration(params, seed):
        return 1.0

    s.create_initial_runs()
    ServerStub.loop(map_params_to_result, map_params_to_duration)

    points = [ ps.params for ps in ParameterSet.all() ]
    print("result: %s" % str(points))
    print("# of runs: %d" % len(Run.all()))

