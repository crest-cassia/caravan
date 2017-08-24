import setting
import tables
import run
import struct

class ParameterSet:

    _dump_fmt = ">q" + "q" * setting.num_inputs


    def __init__(self, ps_id, point):
        self.id = ps_id
        self.point = point
        self.run_ids = []

    def pack_binary(self):
        fmt = self.__class__._dump_fmt
        return struct.pack(fmt, self.id, *self.point)

    @classmethod
    def unpack_binary(cls, bytes):
        fmt = cls._dump_fmt
        t = struct.unpack(fmt, bytes)
        ps = cls( t[0], tuple(t[1:]) )
        return ps

    @classmethod
    def create(cls, point):
        next_id = len( tables.ps_table )
        ps = ParameterSet(next_id, point)
        tables.ps_table.append(ps)
        return ps

    def create_runs(self, num_runs):
        def create_a_run():
            next_seed = len(self.run_ids)
            next_id = len(tables.runs_table)
            r = run.Run(next_id, self.id, next_seed)
            self.run_ids.append(r.id)
            tables.runs_table.append(r)
            return r
        created = []
        for i in range(num_runs):
            r = create_a_run()
            created.append(r)
        return created

    def create_runs_upto(self, target_num):
        current = len(self.run_ids)
        if target_num > current:
            self.create_runs(target_num-current)
        return self.runs()[:target_num]

    def runs(self):
        return [ tables.runs_table[rid] for rid in self.run_ids ]

    def is_finished(self):
        for r in self.runs():
            if not r.is_finished():
                return False
        return True

    def averaged_result(self):
        n = setting.num_outputs
        avg = [0.0] * n
        runs = self.runs()
        for i in range(n):
            results = [ r.results[i] for r in runs ]
            avg[i] = sum(results) / len(results)
        return avg


if __name__ == '__main__':

    def test_ps():
        ps = ParameterSet(500, (2,3,4,5))
        print(ps.__dict__)
    test_ps()

    def test_pack_unpack():
        ps = ParameterSet(500, (2,3,4,5))
        bytes = ps.pack_binary()
        print(bytes)
        ps2 = ParameterSet.unpack_binary(bytes)
        print(ps2.__dict__)
    test_pack_unpack()

    def test_create():
        tables.clear()
        ps = ParameterSet.create((0,1,2))
        print(ps.__dict__)
        print( tables.ps_table[0].__dict__ )
        ps2 = ParameterSet.create((3,4,5))
        print(ps2.__dict__)
    test_create()

    def test_create_runs():
        tables.clear()
        ps = ParameterSet.create((0,1,2))
        runs = ps.create_runs_upto(3)
        print( [ r.id for r in runs] )
        ps2 = ParameterSet.create((0,1,3))
        runs = ps2.create_runs_upto(3)
        print( [ r.id for r in runs] )
    test_create_runs()

    def test_is_finished():
        tables.clear()
        ps = ParameterSet.create((0,1,2))
        assert ps.is_finished() == True
        runs = ps.create_runs_upto(1)
        assert ps.is_finished() == False
        runs[0].store_result( [1.0, 2.0, 3.0], 3, 111, 222 )
        assert ps.is_finished() == True


    test_is_finished()


