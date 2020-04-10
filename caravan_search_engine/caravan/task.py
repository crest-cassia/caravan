from collections import OrderedDict
import json,copy
from .tables import Tables


class Task:
    def __init__(self, task_id, command, input_obj = None):
        self._id = task_id
        if command is not None:
            self._command = command
        self._input = input_obj
        self._rc = None
        self._rank = None
        self._start_at = None
        self._finish_at = None
        self._output = None

    @classmethod
    def create(cls, cmd, input_obj = None):
        tab = Tables.get()
        next_id = len(tab.tasks_table)
        t = cls(next_id, cmd, copy.deepcopy(input_obj) )
        tab.tasks_table.append(t)
        return t

    def id(self):
        """
        Returns
        ---
        task_id : int
        """
        return self._id

    def command(self):
        """
        Returns
        ---
        command : string
        """
        return self._command

    def input(self):
        """
        Returns
        ---
        input : json-like object
        """
        return copy.deepcopy(self._input)

    def rc(self):
        """
        Returns
        ---
        return_code : int or None
        """
        return self._rc

    def rank(self):
        """
        Rank of the MPI process at which the task was executed.
        When the task was cancelled, it is set to -1.

        Returns
        ---
        rank : int or None
        """
        return self._rank

    def start_at(self):
        """
        return the time when the task started. Time is measured as the duration from the beginning of the scheduler process in milliseconds.

        Returns
        ---
        start_at : int or None
        """
        return self._start_at

    def finish_at(self):
        """
        return the time when the task gets completed. Time is measured as the duration from the beginning of the scheduler process in milliseconds.

        Returns
        ---
        finish_at : int or None
        """
        return self._finish_at

    def output(self):
        """
        Returns
        ---
        output : json-like object
        """
        return copy.deepcopy(self._output)

    def is_finished(self):
        """
        true if the task is completed (irrespective of return code is zero or non-zero.)

        Returns
        ---
        flag : boolean
        """
        return self._rank is not None and self._rank >= 0  # negative rank means a cancelled task

    def _store_result(self, output, rc, rank, start_at, finish_at):
        self._output = copy.deepcopy(output)
        self._rc = rc
        self._rank = rank
        self._start_at = start_at
        self._finish_at = finish_at

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
        o["input"] = self._input
        if self._rc is not None:
            o["rc"] = self._rc
            o["rank"] = self._rank
            o["start_at"] = self._start_at
            o["finish_at"] = self._finish_at
            o["output"] = self._output
        return o

    def dumps(self):
        """
        serialize to a JSON string

        Returns
        ---
        str : string
        """
        return json.dumps(self.to_dict())

    def add_callback(self, f):
        """
        set a callback function which is executed when the task is complete.

        Parameters
        ---
        f : callable
        """
        from .server import Server
        Server.watch_task(self, f)

    @classmethod
    def all(cls):
        """
        returns all Tasks

        Returns
        ---
        tasks : list of Tasks
        """
        return Tables.get().tasks_table

    @classmethod
    def find(cls, task_id):
        """
        find a Task

        Parameters
        ---
        task_id : int

        Returns
        ---
        task : Task or None
        """
        return Tables.get().tasks_table[task_id]

    @classmethod
    def reset_cancelled(cls):
        """
        reset all Cancelled tasks (tasks having a negative rank)
        """
        for t in cls.all():
            if t._rank == -1:
                t._rc = None
                t._rank = None
                t._start_at = None
                t._finish_at = None
                t._output = None

    @classmethod
    def _dump_binary(cls, path):
        import msgpack
        with open(path, 'wb') as f:
            def _task_to_obj(t):
                return {"id": t._id, "rc": t._rc, "rank": t._rank, "start_at": t._start_at, "finish_at": t._finish_at, "output": t._output}
            task_results = [ (t._id,_task_to_obj(t)) for t in cls.all() if t.rc() == 0 ]
            b = msgpack.packb( task_results )
            f.write(b)
            f.flush()
