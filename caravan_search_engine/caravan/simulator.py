from collections import OrderedDict
import json,copy
from .tables import Tables
from .parameter_set import ParameterSet
import msgpack

class Simulator:

    def __init__(self, sim_id, command):
        self._id = sim_id
        self._command = command
        self._ps_ids = []

    @classmethod
    def create(cls, command):
        t = Tables.get()
        next_id = len(t.sim_table)
        sim = cls(next_id, command)
        t.sim_table.append(sim)
        return sim

    def id(self):
        return self._id

    def command(self):
        return self._command

    def find_parameter_set(self, params):
        t = Tables.get()
        key = msgpack.packb({"sim": self._id, "v": params})
        if key in t.param_ps_dict:
            return t.param_ps_dict[key]
        else:
            return None

    def find_or_create_parameter_set(self, params):
        t = Tables.get()
        key = msgpack.packb({"sim": self._id, "v": params})
        if key in t.param_ps_dict:
            return t.param_ps_dict[key]
        next_id = len(t.ps_table)
        ps = ParameterSet(next_id, self, params)
        t.ps_table.append(ps)
        t.param_ps_dict[key] = ps
        self._ps_ids.append(ps.id())
        return ps

    def parameter_sets(self):
        return [Tables.get().ps_table[pid] for pid in self._ps_ids]

    def to_dict(self):
        o = OrderedDict()
        o["id"] = self._id
        o["command"] = self._command
        o["ps_ids"] = self._ps_ids
        return o

    @classmethod
    def all(cls):
        return copy.copy(Tables.get().sim_table)  # shallow copy

    @classmethod
    def find(cls, sim_id):
        return Tables.get().sim_table[sim_id]

    def dumps(self):
        return json.dumps(self.to_dict())

