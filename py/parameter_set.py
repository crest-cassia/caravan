import setting
import tables
import run
import struct


class ParameterSet:

    def __init__(self, ps_id, point):
        self.id = ps_id
        self.point = point
        self.run_ids = []

    def pack_binary(self):
        fmt = ">q" + "q" * setting.num_inputs
        return struct.pack(fmt, self.id, *self.point)

    @classmethod
    def unpack_binary(cls, bytes):
        fmt = ">q" + "q" * setting.num_inputs
        t = struct.unpack(fmt, bytes)
        ps = cls(t[0], tuple(t[1:]))
        return ps

    @classmethod
    def byte_size(cls):
        return 8 + 8*setting.num_inputs

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

