import itertools
import tables
import parameter_set

class SearchEngine:

    def __init__(self, ranges, num_runs=1):
        self.ranges = ranges
        self.num_runs = num_runs

    def create_initial_runs(self, srv):
        for point in itertools.product( *self.ranges ):
            ps = parameter_set.ParameterSet.find_or_create(point)
            ps.create_runs_upto(self.num_runs)

