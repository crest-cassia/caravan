import copy
from collections import OrderedDict
from .run import Run
from .tables import Tables


class ParameterSet:

    def __init__(self, ps_id, simulator, params):
        """
        Note
        ---
        Do not call the constructor directory.
        Instead, use `simulator.find_or_create_parameter_set` method to create a ParameterSet.
        """
        self._id = ps_id
        self._sim_id = simulator.id()
        assert isinstance(params, dict)
        self._params = params
        self._run_ids = []

    def id(self):
        """
        Returns
        ---
        ps_id : int
        """
        return self._id

    def v(self):
        """
        returns the parameter dictionary.
        Returned value is a copied value, so you may modify the content.

        Returns
        ---
        v : dictionary
        """
        return copy.deepcopy(self._params)

    def simulator(self):
        """
        Returns
        ---
        sim : Simulator
        """
        return Tables.get().sim_table[self._sim_id]

    def create_runs_upto(self, target_num):
        """
        creates Runs up to the specified number.
        If the PS has no Run yet and target_num=5, 5 Runs are newly created.
        If the PS has 5 or more Runs already, no runs are created.
        List of Runs of size `target_num` is returned.

        Parameters
        ---
        target_num : int

        Returns
        ---
        runs : list of runs
        """
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
        """
        Returns
        ---
        runs : list of runs
        """
        return [Tables.get().tasks_table[rid] for rid in self._run_ids]

    def finished_runs(self):
        """
        returns list of runs that are completed (irrespective of the return code).

        Returns
        ---
        runs : list of runs
        """
        return [r for r in self.runs() if r.is_finished()]

    def is_finished(self):
        """
        returns True if all its Runs are completed.

        Returns
        ---
        flag : boolean
        """
        return all([r.is_finished() for r in self.runs()])

    def outputs(self):
        """
        returns the list of outputs of Runs that are completed with return code zero.

        Returns
        ---
        out : list of json-like object
        """
        return [r.output() for r in self.finished_runs() if r.rc() == 0]

    def to_dict(self):
        """
        serialize to a dictionary

        Returns
        ---
        serialized : dictionary
        """
        o = OrderedDict()
        o["id"] = self._id
        o["sim_id"] = self._sim_id
        o["params"] = self._params
        o["run_ids"] = self._run_ids
        return o

    @classmethod
    def all(cls):
        """
        returns all ParameterSets

        Returns
        ---
        ps_list : list of ParameterSet
        """
        return copy.copy(Tables.get().ps_table)  # shallow copy

    @classmethod
    def find(cls, ps_id):
        """
        find a ParameterSet

        Parameters
        ---
        ps_id : int

        Returns
        ---
        ps : ParameterSet or None
        """
        return Tables.get().ps_table[ps_id]

    def dumps(self):
        """
        serialize to a JSON string

        Returns
        ---
        str : string
        """
        runs_str = ",\n".join(["    " + r.dumps() for r in self.runs()])
        return "{\"id\": %d, \"params\": %s, \"runs\": [\n%s\n]}" % (self._id, str(self._params), runs_str)
