import sys
from collections import defaultdict
from .run import Run
from .parameter_set import ParameterSet

class Server:

    _instance = None

    @classmethod
    def get(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self):
        self.observed_ps = defaultdict(list)
        self.observed_all_ps = defaultdict(list)
        self.max_submitted_run_id = 0

    @classmethod
    def watch_ps(cls, ps, callback):
        cls.get().observed_ps[ ps.id ].append(callback)

    @classmethod
    def watch_all_ps(cls, ps_set, callback ):
        ids = [ ps.id for ps in ps_set ]
        key = tuple( ids )
        cls.get().observed_all_ps[key].append(callback)

    @classmethod
    def loop(cls, map_func):
        self = cls.get()
        self.map_func = map_func
        self._submit()
        while self._has_unfinished_runs():
            r = self._receive_result()
            if r:
                ps = r.parameter_set()
                if ps.is_finished():
                    self._exec_callback()
                self._submit()
            else:
                break

    def _has_callbacks(self):
        return ( len( self.observed_ps ) + len( self.observed_all_ps ) ) > 0

    def _has_unfinished_runs(self):
        for r in Run.all()[:self.max_submitted_run_id]:
            if not r.is_finished():
                return True
        return False

    def _submit(self):
        for r in Run.all()[self.max_submitted_run_id:]:
            if r.is_finished: next
            line = "%d %s\n" % (r.id, self.map_func( r.parameter_set().point, r.seed ))
            sys.stdout.write(line)
        sys.stdout.write("\n")
        self.max_submitted_run_id = len(Run.all())

    def _exec_callback(self):
        while self._check_completed_ps() or self._check_completed_ps_all():
            pass

    def _check_completed_ps(self):
        executed = False
        for psid in list(self.observed_ps.keys()):
            callbacks = self.observed_ps[psid]
            ps = ParameterSet.find(psid)
            while ps.is_finished() and len(callbacks)>0:
                f = callbacks.pop(0)
                f(ps)
                executed = True
        empty_keys = [k for k,v in self.observed_ps.items() if len(v)==0 ]
        for k in empty_keys:
            self.observed_ps.pop(k)
        return executed

    def _check_completed_ps_all(self):
        executed = False
        for psids in list(self.observed_all_ps.keys()):
            pss = [ParameterSet.find(psid) for psid in psids]
            callbacks = self.observed_all_ps[psids]
            while len(callbacks)>0 and all([ps.is_finished() for ps in pss]):
                f = callbacks.pop(0)
                f(pss)
                executed = True
        empty_keys = [k for k,v in self.observed_all_ps.items() if len(v) == 0]
        for k in empty_keys: self.observed_all_ps.pop(k)
        return executed

    def _receive_result(self):
        line = sys.stdin.readline()
        if not line: return None
        line = line.rstrip()
        if not line: return None
        l = line.split(' ')
        rid,rc,place_id,start_at,finish_at = [ int(x) for x in l[:5] ]
        results = [ float(x) for x in l[5:] ]
        r = Run.find(rid)
        r.store_result( results, rc, place_id, start_at, finish_at )
        return r

    def _debug(self):
        sys.stderr.write(str(self.observed_ps)+"\n")
        sys.stderr.write(str(self.observed_all_ps)+"\n")

