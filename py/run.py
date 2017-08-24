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
    def unpack_binary(cls, bytes):
        fmt = cls._dump_fmt
        t = struct.unpack(fmt, bytes)
        r = cls( *t[0:3] )
        results = list( t[3:(3+setting.num_outputs)] )
        r.store_result(results, *t[-3:] )
        return r



if __name__ == '__main__':
    def test_run():
        r = Run(1234, 104, 5678)
        print(r.id)
        print(r.__dict__)
        print(r.is_finished())
        r.store_result( [1.0, 2.0, 3.0], 3, 111, 222)
        print(r.is_finished())
        print(r.__dict__)
    test_run()

    def test_pack_unpack():
        r = Run(1234, 104, 5678)
        r.store_result( [1.0, 2.0, 3.0], 3, 111, 222)
        bytes = r.pack_binary()
        print(bytes)
        r = Run.unpack_binary(bytes)
        print( r.__dict__ )
    test_pack_unpack()

