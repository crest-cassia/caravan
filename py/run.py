import setting
import tables
import struct

class Run:

    _dump_fmt = ">qqq" + "d" * setting.num_outputs + "qqq"


    def __init__(self, run_id, ps_id, seed):
        self.id = run_id
        self.ps_id = ps_id
        self.seed = seed
        self.place_id = -1
        self.start_at = -1
        self.finish_at = -1
        self.results = [0.0] * setting.num_outputs

    def is_finished(self):
        return (self.place_id != -1)

    def parameter_set(self):
        return tables.ps_table[self.ps_id]

    def store_result(self, results, place_id, start_at, finish_at):
        self.results = results
        self.place_id = place_id
        self.start_at = start_at
        self.finish_at = finish_at

    def pack_binary(self):
        fmt = self.__class__._dump_fmt
        return struct.pack(fmt, self.id, self.ps_id, self.seed, *self.results, self.place_id, self.start_at, self.finish_at)

    @classmethod
    def byte_size(cls):
        return 24 + 8*setting.num_outputs + 24

    @classmethod
    def unpack_binary(cls, bytes):
        fmt = cls._dump_fmt
        t = struct.unpack(fmt, bytes)
        r = cls( *t[0:3] )
        results = list( t[3:(3+setting.num_outputs)] )
        r.store_result(results, *t[-3:] )
        return r

