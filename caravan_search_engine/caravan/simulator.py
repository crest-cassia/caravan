from collections import OrderedDict
import json,copy
from .tables import Tables
from .parameter_set import ParameterSet
import msgpack

class Simulator:
    """
    A class corresponding to an executable program.
    """

    def __init__(self, sim_id, command):
        """
        Note
        ---
        Do not call the constructor directory.
        Instead, use `Simulator.create(command)` to create a new Simulator.
        """
        self._id = sim_id
        self._command = command
        self._ps_ids = []

    @classmethod
    def create(cls, command):
        """
        create a new Simulator instance.

        Returns
        ---
        sim : Simulator
        """
        t = Tables.get()
        next_id = len(t.sim_table)
        sim = cls(next_id, command)
        t.sim_table.append(sim)
        return sim

    def id(self):
        """
        Returns
        ---
        simulator_id : int
        """
        return self._id

    def command(self):
        """
        Returns
        ---
        command : string
        """
        return self._command

    def find_parameter_set(self, params):
        """
        returns the ParameterSet whose parameters are identical to `params`.
        If no matching result is found, None is returned.

        Parameters
        ---
        params : dictionary
            dictionary specifying parameters (e.g. {"p1":1, "p2": 0.5})

        Returns
        ---
        ps : ParameterSet or None
        """
        t = Tables.get()
        key = msgpack.packb({"sim": self._id, "v": params})
        if key in t.param_ps_dict:
            return t.param_ps_dict[key]
        else:
            return None

    def find_or_create_parameter_set(self, params):
        """
        returns the ParameterSet whose parameters are identical to `params`.
        If no matching result is found, a new ParameterSet is created.

        Parameters
        ---
        params : dictionary
            dictionary specifying parameters (e.g. {"p1":1, "p2": 0.5})

        Returns
        ---
        ps : ParameterSet
        """
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
        """
        returns the list of ParameterSets

        Returns
        ---
        ps_list : list of ParameterSet
        """
        return [Tables.get().ps_table[pid] for pid in self._ps_ids]

    def to_dict(self):
        """
        serialize to a dictionary

        Returns
        ---
        serialized : dictionary
        """
        o = OrderedDict()
        o["id"] = self._id
        o["command"] = self._command
        o["ps_ids"] = self._ps_ids
        return o

    @classmethod
    def all(cls):
        """
        returns all Simulators

        Returns
        ---
        sims : list of Simulators
        """
        return copy.copy(Tables.get().sim_table)  # shallow copy

    @classmethod
    def find(cls, sim_id):
        """
        find a Simulator

        Parameters
        ---
        sim_id : int

        Returns
        ---
        sim : Simulator or None
        """
        return Tables.get().sim_table[sim_id]

    def dumps(self):
        """
        serialize to a JSON string

        Returns
        ---
        str : string
        """
        return json.dumps(self.to_dict())

