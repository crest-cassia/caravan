import sys, threading
from queue import Queue

_current_fiber = None


def set_current_fiber(f):
    global _current_fiber
    _current_fiber = f


def current():
    global _current_fiber
    if _current_fiber is None:
        _current_fiber = _create_main_fiber()
    return _current_fiber


class Fiber:
    def __init__(self, target=None, args=[], kwargs={}):
        def _run():
            try:
                self._q.get()
                self._exc_info = None
                set_current_fiber(self)
                return target(*args, **kwargs)
            except:
                self._exc_info = sys.exc_info()
            finally:
                self._ended = True
                parent = self._get_active_parent()
                if self._exc_info:
                    parent._q.put(self._exc_info)
                else:
                    parent._q.put(0)

        self._ended = False
        self._q = Queue()
        self._th = threading.Thread(target=_run, daemon=True)

        self.parent = current()  # only the root fiber's parent is None
        self._th.start()

    def _get_active_parent(self):
        parent = self.parent
        while True:
            if parent is not None and not parent._ended:
                break
            parent = parent.parent
        return parent

    @classmethod
    def current(cls):
        return current()

    @property
    def parent(self):
        return self.__dict__.get('parent', None)

    @parent.setter
    def parent(self, value):
        if not isinstance(value, Fiber):
            raise TypeError('parent must be a Fiber')
        self.__dict__['parent'] = value

    def switch(self):
        if not self._th.is_alive():
            raise error('Fiber has ended')

        curr = current()
        self._q.put(0)
        set_current_fiber(self)
        x = curr._q.get()
        if x != 0:
            raise x[1].with_traceback(x[2])

    def is_alive(self):
        return not self._ended

    def __getstate__(self):
        raise TypeError('cannot serialize Fiber object')


def _create_main_fiber():
    main_fiber = Fiber.__new__(Fiber)
    main_fiber.__dict__['parent'] = None
    main_fiber.__dict__['_th'] = threading.current_thread()
    main_fiber.__dict__['_q'] = Queue()
    main_fiber.__dict__['_ended'] = False
    return main_fiber
