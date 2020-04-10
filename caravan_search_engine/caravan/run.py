from collections import OrderedDict
import json
from .tables import Tables
from .task import Task


class Run(Task):
    def __init__(self, run_id, ps, seed):
        """
        Note
        ---
        Do not call the constructor directory.
        Instead, use `parameter_set.create_runs_upto` method to create a Run.
        """
        input_obj = ps.v()
        input_obj['_seed'] = seed
        super().__init__(run_id, ps.simulator().command(), input_obj)
        self._ps_id = ps.id()
        self._seed = seed

    def parameter_set(self):
        """
        Returns
        ---
        parent_ps : ParameterSet
        """
        return Tables.get().ps_table[self._ps_id]

    def seed(self):
        """
        Returns
        ---
        seed : int
        """
        return self._seed

    def to_dict(self):
        """
        Returns
        ---
        serialized : dictionary
        """
        o = super().to_dict()
        o["ps_id"] = self._ps_id
        o["seed"] = self._seed
        return o

    @classmethod
    def all(cls):
        """
        returns all Runs

        Returns
        ---
        runs : list of Runs
        """
        return [t for t in Tables.get().tasks_table if isinstance(t, cls)]

    def dumps(self):
        """
        serialize to a JSON string

        Returns
        ---
        str : string
        """
        return json.dumps(self.to_dict())
