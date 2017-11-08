import tables

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
        return tables.ps_table[self.ps_id]

    def store_result(self, results, rc, place_id, start_at, finish_at):
        self.results = results
        self.rc = rc
        self.place_id = place_id
        self.start_at = start_at
        self.finish_at = finish_at

    def dumps(self):
        results_str = str(self.results)
        return "{\"id\": %d, \"seed\": %s, \"rc\": %s, \"place_id\": %s, \"start_at\": %s, \"finish_at\" %s, \"results\": %s}" % (self.id, self.seed, self.rc, self.place_id, self.start_at, self.finish_at, results_str)

