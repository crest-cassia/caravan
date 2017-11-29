import itertools
from searcher.parameter_set import ParameterSet
from searcher.run import Run

class ComprehensiveSearcher:

    def __init__(self, ranges, num_runs=1):
        self.ranges = ranges
        self.num_runs = num_runs

    def create_initial_runs(self):
        for point in itertools.product( *self.ranges ):
            ps = ParameterSet.find_or_create(point)
            ps.create_runs_upto(self.num_runs)

if __name__ == "__main__":
    from searcher.server_stub import ServerStub

    ranges = [
        range(-2, 3),
        range(0, 2)
    ]

    s = ComprehensiveSearcher(ranges, num_runs=2)

    def map_point_to_result(point, seed):
        return [point[0]**2 + point[1]**2]

    def map_point_to_duration(point, seed):
        return 1.0

    s.create_initial_runs()
    ServerStub.loop(map_point_to_result, map_point_to_duration)

    points = [ ps.point for ps in ParameterSet.all() ]
    print("result: %s" % str(points))
    print("# of runs: %d" % len(Run.all()))

