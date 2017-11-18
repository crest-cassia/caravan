from collections import OrderedDict
import tables
import run

class ParameterSet:

    def __init__(self, ps_id, point):
        self.id = ps_id
        self.point = tuple(point)
        self.run_ids = []

    @classmethod
    def find_or_create(cls, point):
        p = tuple(point)
        if p in tables.ps_point_table:
            return tables.ps_point_table[p]
        next_id = len(tables.ps_table)
        ps = cls(next_id, p)
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
        return all([r.is_finished() for r in self.runs()])

    def averaged_result(self):
        runs = [ r for r in self.finished_runs() if r.rc == 0 ]
        if len(runs) == 0:
            return []
        else:
            n = len( runs[0].results )
            averages = []
            for i in range(n):
                results = [r.results[i] for r in runs if r.results[i] ]
                avg = sum(results) / len(results)
                averages.append(avg)
            return averages

    def to_dict(self):
        o = OrderedDict()
        o["id"] = self.id
        o["point"] = self.point
        o["run_ids"] = self.run_ids
        return o

    @classmethod
    def new_from_dict(cls, o):
        ps = cls( o["id"], o["point"] )
        ps.run_ids = o["run_ids"]
        return ps

    def dumps(self):
        runs_str = ",\n".join( [ "    " + r.dumps() for r in self.runs()] )
        return "{\"id\": %d, \"point\": %s, \"runs\": [\n%s\n]}" % (self.id, str(self.point), runs_str)

