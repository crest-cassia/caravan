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
        return self._id

    def command(self):
        return self._command

    def input(self):
        return copy.deepcopy(self._input)

    def rc(self):
        return self._rc

    def rank(self):
        return self._rank

    def start_at(self):
        return self._start_at

    def finish_at(self):
        return self._finish_at

    def output(self):
        return copy.deepcopy(self._output)

    def is_finished(self):
        return self._rc is not None

    def store_result(self, output, rc, rank, start_at, finish_at):
        self._output = copy.deepcopy(output)
        self._rc = rc
        self._rank = rank
        self._start_at = start_at
        self._finish_at = finish_at

    def to_dict(self):
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
        return json.dumps(self.to_dict())

    def add_callback(self, f):
        from .server import Server
        Server.watch_task(self, f)

    @classmethod
    def all(cls):
        return Tables.get().tasks_table

    @classmethod
    def find(cls, id):
        return Tables.get().tasks_table[id]

    @classmethod
    def reset_cancelled(cls):
        for t in cls.all():
            if t._rank == -1:
                t._rc = None
                t._rank = None
                t._start_at = None
                t._finish_at = None
                t._output = None

    @classmethod
    def dump_binary(cls, path):
        import msgpack
        with open(path, 'wb') as f:
            def _task_to_obj(t):
                return {"id": t._id, "rc": t._rc, "rank": t._rank, "start_at": t._start_at, "finish_at": t._finish_at, "output": t._output}
            task_results = { t._id:_task_to_obj(t) for t in cls.all() if t.rc() == 0 }
            b = msgpack.packb( task_results )
            f.write(b)
            f.flush()
