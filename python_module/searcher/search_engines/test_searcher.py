import itertools
import tables
import parameter_set
import sys, json

class TestSearcher:

    def __init__(self, ranges, num_runs=1):
        self.ranges = ranges
        self.num_runs = num_runs

    def create_initial_runs(self, srv):
        self.srv = srv
        for point in itertools.product( *self.ranges ):
            ps = parameter_set.ParameterSet.find_or_create(point)
            ps.create_runs_upto(self.num_runs)
            self.srv.watch_ps( ps, self._on_ps_finished )
        self.srv.watch_all_ps( tables.ps_table[0:2], self._on_ps_all_finished )

    def _on_ps_finished(self, ps):
        sys.stderr.write( "finished : %s\n" % json.dumps(ps.__dict__))
        for r in ps.runs():
            sys.stderr.write( "  run : %s\n" % json.dumps(r.__dict__))
        ps.create_runs_upto(self.num_runs + 1)
        if len(ps.runs()) - len(ps.finished_runs()) > 0:
            self.srv.watch_ps(ps, self._on_ps_finished)

    def _on_ps_all_finished(self, ps_list):
        sys.stderr.write("finished ps_all: %s\n" % str([ps.id for ps in ps_list]))

