import sys,logging,os,struct,socket
import msgpack
from collections import defaultdict

if os.getenv("CARAVAN_USE_PSEUDO_FIBER") == "1":  # for debugging pseudo_fiber
    from .pseudo_fiber import Fiber
else:
    try:
        from fibers import Fiber
    except ImportError:
        from .pseudo_fiber import Fiber
from .task import Task
from .run import Run
from .parameter_set import ParameterSet
from mpi4py import MPI


class Server(object):
    _instance = None

    @classmethod
    def _get(cls):
        if cls._instance is None:
            raise Exception("use Server.start() method")
        return cls._instance

    def __init__(self, logger=None):
        """
        Note
        ---
        Do not call the constructor directory.
        Instead, use `Server.start` to launch a server.
        """
        self.observed_ps = defaultdict(list)
        self.observed_all_ps = defaultdict(list)
        self.observed_task = defaultdict(list)
        self.observed_all_tasks = defaultdict(list)  # (task_id) => list of (task_ids, callback)
        self.max_submitted_task_id = 0
        self._logger = logger or self._default_logger()
        self._fibers = []
        self._comm = None

    @classmethod
    def start(cls, logger=None):
        """
        start a scheduling of tasks.

        Examples
        ---
        >>> with Server.start():
            ....
        """
        cls._instance = cls(logger)
        return cls._instance

    def __enter__(self):
        self._loop_fiber = Fiber(target=self._loop)
        self._comm = MPI.Comm.Get_parent()
        self._logger.debug("accepted")

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            return False  # re-raise exception
        if self._loop_fiber.is_alive():
            self._loop_fiber.switch()
        self._comm.Disconnect()

    @classmethod
    def watch_ps(cls, ps, callback):
        """
        add a callback function when ps gets completed.

        Parameters
        ---
        ps : ParameterSet
        callback : callable
        """
        cls._get().observed_ps[ps.id()].append(callback)

    @classmethod
    def watch_all_ps(cls, ps_set, callback):
        """
        add a callback function when a set of ParameterSets is completed.

        Parameters
        ---
        ps_set : list of ParameterSet
        callback : callable
        """
        ids = [ps.id() for ps in ps_set]
        key = tuple(ids)
        cls._get().observed_all_ps[key].append(callback)

    @classmethod
    def watch_task(cls, task, callback):
        """
        add a callback function when a Task is completed.

        Parameters
        ---
        task : Task
        callback : callable
        """
        cls._get().observed_task[task.id()].append(callback)

    @classmethod
    def watch_all_tasks(cls, tasks, callback):
        """
        add a callback function when a set of Tasks is completed.

        Parameters
        ---
        tasks : list of Task
        callback : callable
        """
        key = tuple([t.id() for t in tasks])
        for t in tasks:
            pair = (key, callback)
            cls._get().observed_all_tasks[t.id()].append(pair)

    @classmethod
    def do_async(cls, func, *args, **kwargs):
        """
        do coroutine asynchronously.

        Examples
        ---
        Server.do_async( lambda : Task.create(...) )

        Parameters
        ---
        tasks : list of Task
        callback : callable
        """
        self = cls._get()

        def _f():
            func(*args, **kwargs)
            self._loop_fiber.switch()

        fb = Fiber(target=_f)
        self._fibers.append(fb)

    @classmethod
    def await_ps(cls, ps):
        """
        wait until parameterSet is complete.
        During waiting, other co-routines are concurrently executed.

        Parameters
        ---
        ps : ParameterSet
        """
        self = cls._get()
        fb = Fiber.current()

        def _callback():
            self._fibers.append(fb)

        cls.watch_ps(ps, _callback)
        self._loop_fiber.switch()

    @classmethod
    def await_all_ps(cls, ps_set):
        """
        wait until a set of ParameterSets is complete.
        While waiting, other co-routines are concurrently executed.

        Parameters
        ---
        ps_set : list of ParameterSet
        """
        self = cls._get()
        fb = Fiber.current()

        def _callback():
            self._fibers.append(fb)

        cls.watch_all_ps(ps_set, _callback)
        self._loop_fiber.switch()

    @classmethod
    def await_task(cls, task):
        """
        wait until a Task is complete.

        Parameters
        ---
        task : Task
        """
        self = cls._get()
        fb = Fiber.current()

        def _callback():
            self._fibers.append(fb)

        cls.watch_task(task, _callback)
        self._loop_fiber.switch()

    @classmethod
    def await_all_tasks(cls, tasks):
        """
        wait until a set of Tasks is complete.

        Parameters
        ---
        tasks : list of Task
        """
        self = cls._get()
        fb = Fiber.current()

        def _callback():
            self._fibers.append(fb)

        cls.watch_all_tasks(tasks, _callback)
        self._loop_fiber.switch()

    def _loop(self):
        self._launch_all_fibers()
        self._submit_all()
        self._logger.debug("start polling")
        t = self._receive_result()
        while t:
            self._exec_callback_for_task(t)
            self._exec_callback_for_all_task(t)
            if isinstance(t, Run):
                ps = t.parameter_set()
                if ps.is_finished():
                    self._exec_callback()
            self._submit_all()
            t = self._receive_result()

    def _default_logger(self):
        logger = logging.getLogger(__name__)
        log_level = logging.INFO
        if 'CARAVAN_SEARCH_ENGINE_LOGLEVEL' in os.environ:
            s = os.environ['CARAVAN_SEARCH_ENGINE_LOGLEVEL']
            levels = {'DEBUG': logging.DEBUG, 'INFO': logging.INFO, 'WARNING': logging.WARNING, 'ERROR': logging.ERROR,
                      'CRITICAL': logging.CRITICAL}
            log_level = levels[s]
        logger.setLevel(log_level)
        logger.propagate = False
        if not logger.handlers:
            ch = logging.StreamHandler()
            ch.setLevel(log_level)
            formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
            ch.setFormatter(formatter)
            logger.addHandler(ch)
        return logger

    def _has_callbacks(self):
        return (len(self.observed_ps) + len(self.observed_all_ps)) > 0

    def _has_unfinished_tasks(self):
        for r in Task.all()[:self.max_submitted_task_id]:
            if not r.is_finished():
                return True
        return False

    def _submit_all(self):
        tasks_to_be_submitted = [t for t in Task.all()[self.max_submitted_task_id:] if not t.is_finished()]
        self._logger.debug("submitting %d Tasks" % len(tasks_to_be_submitted))
        self._print_tasks(tasks_to_be_submitted)
        self.max_submitted_task_id = len(Task.all())

    def _print_tasks(self, tasks):
        b_tasks = [ {"id": t.id(), "cmd": t.command(), "input": t.input()} for t in tasks ]
        packed = msgpack.packb(b_tasks)
        self._comm.Send([bytearray(packed),MPI.CHAR], dest=0, tag=0)
        self._logger.debug(f"sent packed")

    def _launch_all_fibers(self):
        while self._fibers:
            f = self._fibers.pop(0)
            self._logger.debug("starting fiber")
            f.switch()

    def _exec_callback(self):
        while self._check_completed_ps() or self._check_completed_ps_all():
            pass

    def _check_completed_ps(self):
        executed = False
        for psid in list(self.observed_ps.keys()):
            callbacks = self.observed_ps[psid]
            ps = ParameterSet.find(psid)
            while ps.is_finished() and len(callbacks) > 0:
                self._logger.debug("executing callback for ParameterSet %d" % ps.id())
                f = callbacks.pop(0)
                f()
                self._launch_all_fibers()
                executed = True
        empty_keys = [k for k, v in self.observed_ps.items() if len(v) == 0]
        for k in empty_keys:
            self.observed_ps.pop(k)
        return executed

    def _check_completed_ps_all(self):
        executed = False
        for psids in list(self.observed_all_ps.keys()):
            pss = [ParameterSet.find(psid) for psid in psids]
            callbacks = self.observed_all_ps[psids]
            while len(callbacks) > 0 and all([ps.is_finished() for ps in pss]):
                self._logger.debug("executing callback for ParameterSet %s" % repr(psids))
                f = callbacks.pop(0)
                f()
                self._launch_all_fibers()
                executed = True
        empty_keys = [k for k, v in self.observed_all_ps.items() if len(v) == 0]
        for k in empty_keys: self.observed_all_ps.pop(k)
        return executed

    def _exec_callback_for_task(self,task):
        executed = False
        callbacks = self.observed_task[task.id()]
        while len(callbacks) > 0:
            self._logger.debug("executing callback for Task %d" % task.id())
            f = callbacks.pop(0)
            f()
            self._launch_all_fibers()
            executed = True
        self.observed_task.pop(task.id())
        return executed

    def _exec_callback_for_all_task(self, task):
        executed = False
        callback_pairs = self.observed_all_tasks[task.id()]
        to_be_removed = []
        for (idx, pair) in enumerate(callback_pairs):
            task_ids = pair[0]
            if all([Task.find(t).is_finished() for t in task_ids]):
                self._logger.debug("executing callback for Tasks %s" % str(task_ids))
                f = pair[1]
                f()
                to_be_removed.append(idx)
                self._launch_all_fibers()
                executed = True
        for idx in to_be_removed:
            callback_pairs.pop(idx)
        if len(callback_pairs) == 0:
            self.observed_all_tasks.pop(task.id())
        return executed

    def _receive_bytes(self):
        s = MPI.Status()
        self._comm.Probe(status=s)
        if s.count == 0: assert s.tag == 1
        recvbuf = bytearray(s.count)
        self._comm.Recv([recvbuf, s.count, MPI.CHAR], source=s.source, tag=s.tag)
        return recvbuf

    def _receive_result(self):
        data_b = self._receive_bytes()
        if len(data_b) == 0: return None
        self._logger.debug("received: %s bytes" % len(data_b))
        unpacked = msgpack.unpackb(data_b)
        self._logger.debug("received: %s" % str(unpacked))
        tid = unpacked["id"]
        rc = unpacked["rc"]
        rank = unpacked["rank"]
        start_at = unpacked["start_at"]
        finish_at = unpacked["finish_at"]
        output = unpacked["output"]
        t = Task.find(tid)
        t._store_result(output, rc, rank, start_at, finish_at)
        self._logger.debug("stored result of Task %d" % tid)
        return t

    def _debug(self):
        sys.stderr.write(str(self.observed_ps) + "\n")
        sys.stderr.write(str(self.observed_all_ps) + "\n")
