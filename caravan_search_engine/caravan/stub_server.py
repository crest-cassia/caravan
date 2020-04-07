import os,bisect
if os.getenv("CARAVAN_USE_PSEUDO_FIBER") == "1":  # for debugging pseudo_fiber
    from .pseudo_fiber import Fiber
else:
    try:
        from fibers import Fiber
    except ImportError:
        from .pseudo_fiber import Fiber
from .server import Server
from .task import Task


class EventQueue:
    def __init__(self, num_places):
        self.n = num_places
        self.sleeping_places = list(range(self.n))
        self.running_tasks = []
        self.finish_at_list = []
        self.t = 0
        self.tasks = []

    def push_all(self, tasks):
        self.tasks.extend(tasks)

    def pop(self):
        while len(self.sleeping_places) > 0 and len(self.tasks) > 0:
            place = self.sleeping_places.pop(0)
            starting = self.tasks.pop(0)
            starting._start_at = self.t
            starting._finish_at = self.t + starting._dt
            starting._rank = place
            f = starting._finish_at
            idx = bisect.bisect_right(self.finish_at_list, f)
            self.finish_at_list.insert(idx, f)
            self.running_tasks.insert(idx, starting)

        if len(self.sleeping_places) == self.n:
            return None
        else:
            self.finish_at_list.pop(0)
            next_task = self.running_tasks.pop(0)
            self.t = next_task._finish_at
            p = next_task._rank
            self.sleeping_places.append(p)
            return next_task

class StubServer(Server):

    def __init__(self, stub_simulator, num_proc, logger, dump_path):
        super().__init__(logger)
        self._stub_simulator = stub_simulator
        self._num_proc = num_proc
        self._dump_path = dump_path
        self._queue = EventQueue(self._num_proc)

    @classmethod
    def start(cls, stub_simulator, num_proc, logger=None, dump_path='tasks.msgpack'):
        Server._instance = cls(stub_simulator, num_proc, logger, dump_path)
        return Server._instance

    # override the methods
    def _print_tasks(self, tasks):
        for t in tasks:
            res, dt = self._stub_simulator(t)
            t._output = res
            t._dt = int(1000 * dt)
        self._queue.push_all(tasks)

    def _receive_result(self):
        t = self._queue.pop()
        if t is None:
            return None
        t._rc = 0
        return t

    def __enter__(self):
        self._loop_fiber = Fiber(target=self._loop)

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            return False  # re-raise exception
        if self._loop_fiber.is_alive():
            self._loop_fiber.switch()
        Task.dump_binary(self._dump_path)

