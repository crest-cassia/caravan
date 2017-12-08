from collections import OrderedDict
import json
from . import tables

class Run:

    def __init__(self, run_id, ps_id, seed):
        self.id = run_id
        self.ps_id = ps_id
        self.seed = seed
        self.rc = None
        self.place_id = None
        self.start_at = None
        self.finish_at = None
        self.results = None

    def is_finished(self):
        return not (self.rc is None)

    def parameter_set(self):
        return tables.Tables.get().ps_table[self.ps_id]

    def store_result(self, results, rc, place_id, start_at, finish_at):
        self.results = results
        self.rc = rc
        self.place_id = place_id
        self.start_at = start_at
        self.finish_at = finish_at

    def to_dict(self):
        o = OrderedDict()
        o["id"] = self.id
        o["ps_id"] = self.ps_id
        o["seed"] = self.seed
        o["rc"] = self.rc
        o["place_id"] = self.place_id
        o["start_at"] = self.start_at
        o["finish_at"] = self.finish_at
        o["results"] = self.results
        return o

    @classmethod
    def new_from_dict(cls, o):
        r = cls( o["id"], o["ps_id"], o["seed"] )
        r.store_result(o["results"], o["rc"], o["place_id"], o["start_at"], o["finish_at"])
        return r

    @classmethod
    def all(cls):
        return tables.Tables.get().runs_table

    @classmethod
    def find(cls,id):
        return tables.Tables.get().runs_table[id]

    def dumps(self):
        return json.dumps( self.to_dict() )

