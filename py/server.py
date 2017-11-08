import sys
import tables
from collections import defaultdict

class Server:

    def __init__(self, search_engine, map_func):
        self.engine = search_engine
        self.map_func = map_func
        self.observed_ps = defaultdict(list)
        self.observed_all_ps = defaultdict(list)
        self.max_submitted_run_id = 0

    def watch_ps(self, ps, callback):
        self.observed_ps[ ps.id ].append(callback)

    def watch_all_ps(self, ps_set, callback ):
        ids = [ ps.id for ps in ps_set ]
        key = tuple( sorted(ids) )
        self.observed_all_ps[key].append(callback)

    def run(self):
        self.engine.create_initial_runs(self)
        self._submit()

        while self._is_waiting():
            r = self._receive_result()
            if r:
                ps = r.parameter_set()
                if ps.is_finished():
                    self._exec_callback(ps)
                    self._submit()
            else:
                break

    def _is_waiting(self):
        return ( len( self.observed_ps ) + len( self.observed_all_ps ) ) > 0

    def _submit(self):
        for r in tables.runs_table[self.max_submitted_run_id:]:
            line = "%d %s\n" % (r.id, self.map_func( r.parameter_set().point, r.seed ))
            sys.stdout.write(line)
        sys.stdout.write("\n")
        self.max_submitted_run_id = len(tables.runs_table)

    def _exec_callback(self, ps):
        if ps.id in self.observed_ps:
            callbacks = self.observed_ps[ps.id]
            while callbacks:
                f = callbacks.pop(0)
                f(ps)
                if not ps.is_finished(): return
            self.observed_ps.pop( ps.id )
        for psids in self.observed_all_ps:
            if ps.id in psids:
                pss = [tables.ps_table[psid] for psid in psids]
                callbacks = self.observed_all_ps[psids]
                while callbacks:
                    if all([ps.is_finished() for ps in pss]):
                        f = callbacks.pop(0)
                        f(pss)
                    else: break
        empty_keys = [k for k,v in self.observed_all_ps.items() if len(v) == 0]
        for k in empty_keys: self.observed_all_ps.pop(k)

    def _receive_result(self):
        line = sys.stdin.readline()
        line = line.rstrip()
        if not line:
            return None
        l = line.split(' ')
        rid,rc,place_id,start_at,finish_at = [ int(x) for x in l[:5] ]
        results = [ float(x) for x in l[5:] ]
        r = tables.runs_table[rid]
        r.store_result( results, rc, place_id, start_at, finish_at )
        return r

    def _debug(self):
        sys.stderr.write(str(self.observed_ps)+"\n")
        sys.stderr.write(str(self.observed_all_ps)+"\n")


