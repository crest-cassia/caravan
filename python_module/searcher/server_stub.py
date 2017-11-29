from .server import Server

class EventQueue:

    def __init__(self,num_places):
        self.n = num_places
        self.running = [ None for i in range(self.n) ]
        self.t = 0
        self.runs = []

    def push_all(self,runs):
        self.runs.extend(runs)
        #print([r.parameter_set().point for r in runs])

    def pop(self):
        while None in self.running and len(self.runs)>0:
            idx = self.running.index(None)
            starting = self.runs.pop(0)
            starting.start_at = self.t
            starting.finish_at = self.t + starting.dt
            starting.place_id = idx
            self.running[idx] = starting

        compacted = [r for r in self.running if r is not None]
        if len(compacted) == 0:
            return None
        else:
            next_run = min(compacted, key=(lambda r: r.finish_at))
            self.t = next_run.finish_at
            idx = self.running.index(next_run)
            self.running[idx] = None
            return next_run


class ServerStub:

    _map_point_to_results = None
    _map_point_to_duration = None

    @classmethod
    def loop(cls, map_point_to_results, map_point_to_duration, num_proc=1):
        cls._map_point_to_results = map_point_to_results
        cls._map_point_to_duration = map_point_to_duration
        queue = EventQueue(num_proc)

        # override the methods
        def print_tasks_stub(self,runs):
            for r in runs:
                point = r.parameter_set().point
                r.dt = map_point_to_duration(point, r.seed)
            queue.push_all(runs)
        Server._print_tasks = print_tasks_stub
        def receive_result_stub(self):
            r = queue.pop()
            point = r.parameter_set().point
            r.results = map_point_to_results(point, r.seed)
            r.rc = 0
            return r
        Server._receive_result = receive_result_stub

        Server.loop(None)

