from collections import OrderedDict
import json
from .tables import Tables
from .task import Task


class Run(Task):
    def __init__(self, run_id, ps, seed):
        input_obj = ps.v()
        input_obj['_seed'] = seed
        super().__init__(run_id, ps.simulator().command(), input_obj)
        self._ps_id = ps.id()
        self._seed = seed

    def parameter_set(self):
        return Tables.get().ps_table[self._ps_id]

    def seed(self):
        return self._seed

    def to_dict(self):
        o = super().to_dict()
        o["ps_id"] = self._ps_id
        o["seed"] = self._seed
        return o

    @classmethod
    def all(cls):
        return [t for t in Tables.get().tasks_table if isinstance(t, cls)]

    def dumps(self):
        return json.dumps(self.to_dict())
