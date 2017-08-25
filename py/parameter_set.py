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
        ps = cls(t[0], tuple(t[1:]))
        return ps

    @classmethod
    def find_or_create(cls, point):
        p = tuple(point)
        if p in tables.ps_point_table:
            return tables.ps_point_table[p]
        next_id = len(tables.ps_table)
        ps = ParameterSet(next_id, p)
        tables.ps_table.append(ps)
        tables.ps_point_table[p] = ps
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
            self.create_runs(target_num - current)
        return self.runs()[:target_num]

    def runs(self):
        return [tables.runs_table[rid] for rid in self.run_ids]

    def finished_runs(self):
        return [tables.runs_table[rid] for rid in self.run_ids if tables.runs_table[rid].is_finished()]

    def is_finished(self):
        for r in self.runs():
            if not r.is_finished():
                return False
        return True

    def averaged_result(self):
        n = setting.num_outputs
        avg = [None] * n
        runs = self.finished_runs()
        if len(runs) > 0:
            for i in range(n):
                results = [r.results[i] for r in runs]
                avg[i] = sum(results) / len(results)
        return avg


if __name__ == '__main__':
    def test_ps():
        ps = ParameterSet(500, (2, 3, 4, 5))
        assert ps.id == 500
        assert ps.point == (2, 3, 4, 5)
        assert ps.run_ids == []
        print(ps.__dict__)

    test_ps()

    def test_pack_unpack():
        ps = ParameterSet(500, (2, 3, 4, 5))
        bytes = ps.pack_binary()
        ps2 = ParameterSet.unpack_binary(bytes)
        print(ps2.__dict__)
        assert ps.id == ps2.id
        assert ps.point == ps2.point

    test_pack_unpack()

    def test_create():
        tables.clear()
        ps = ParameterSet.find_or_create((0, 1, 2, 3))
        assert ps.id == 0
        assert ps.point == (0, 1, 2, 3)
        assert len(tables.ps_table) == 1
        assert len(tables.ps_point_table) == 1
        ps2 = ParameterSet.find_or_create((3, 4, 5, 6))
        assert len(tables.ps_table) == 2
        assert len(tables.ps_point_table) == 2
        print(ps2.__dict__)
        assert tables.ps_point_table[(3, 4, 5, 6)] == ps2

        ps3 = ParameterSet.find_or_create((0, 1, 2, 3))
        assert ps == ps3
        assert len(tables.ps_table) == 2
        assert len(tables.ps_point_table) == 2

    test_create()

    def test_create_runs():
        tables.clear()
        ps = ParameterSet.find_or_create((0, 1, 2, 3))
        runs = ps.create_runs_upto(3)
        assert [r.id for r in runs] == [0, 1, 2]
        ps2 = ParameterSet.find_or_create((0, 1, 3, 4))
        runs = ps2.create_runs_upto(3)
        assert [r.id for r in runs] == [3, 4, 5]

    test_create_runs()

    def test_is_finished():
        tables.clear()
        ps = ParameterSet.find_or_create((0, 1, 2, 3))
        assert ps.is_finished() == True
        runs = ps.create_runs_upto(1)
        assert ps.is_finished() == False
        assert len(ps.finished_runs()) == 0
        runs[0].store_result([1.0, 2.0, 3.0], 3, 111, 222)
        assert ps.is_finished() == True
        assert len(ps.finished_runs()) == 1

    test_is_finished()

    def test_averaged_result():
        tables.clear()
        ps = ParameterSet.find_or_create((0, 1, 2, 3))
        runs = ps.create_runs_upto(3)
        assert ps.averaged_result() == [None] * setting.num_outputs
        for (i,r) in enumerate(runs):
            r.store_result([1.0+i, 2.0+i, 3.0+1], 3, 111, 222)
        assert ps.averaged_result() == [2.0, 3.0, 4.0]

    test_averaged_result()

