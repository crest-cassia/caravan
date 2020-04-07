import copy
from collections import OrderedDict
from .run import Run
from .tables import Tables


class ParameterSet:

    def __init__(self, ps_id, simulator, params):
        self._id = ps_id
        self._sim_id = simulator.id()
        assert isinstance(params, dict)
        self._params = params
        self._run_ids = []

    def id(self):
        return self._id

    def v(self):
        return copy.deepcopy(self._params)

    def simulator(self):
        return Tables.get().sim_table[self._sim_id]

    def create_runs_upto(self, target_num):
        current = len(self._run_ids)
        while target_num > current:
            t = Tables.get()
            next_id = len(t.tasks_table)
            run = Run(next_id, self, current)
            self._run_ids.append(run.id())
            t.tasks_table.append(run)
            current += 1
        return self.runs()[:target_num]

    def runs(self):
        return [Tables.get().tasks_table[rid] for rid in self._run_ids]

    def finished_runs(self):
        return [r for r in self.runs() if r.is_finished()]

    def is_finished(self):
        return all([r.is_finished() for r in self.runs()])

    def outputs(self):
        return [r.output() for r in self.finished_runs() if r.rc() == 0]

    def to_dict(self):
        o = OrderedDict()
        o["id"] = self._id
        o["sim_id"] = self._sim_id
        o["params"] = self._params
        o["run_ids"] = self._run_ids
        return o

    @classmethod
    def all(cls):
        return copy.copy(Tables.get().ps_table)  # shallow copy

    @classmethod
    def find(cls, ps_id):
        return Tables.get().ps_table[ps_id]

    def dumps(self):
        runs_str = ",\n".join(["    " + r.dumps() for r in self.runs()])
        return "{\"id\": %d, \"params\": %s, \"runs\": [\n%s\n]}" % (self._id, str(self._params), runs_str)
