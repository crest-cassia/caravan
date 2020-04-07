import pickle


class Tables:
    _instance = None

    @classmethod
    def get(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self):
        if self.__class__._instance is not None:
            raise "do not call constructor directly"
        self.clear()

    def clear(self):
        self.sim_table = []
        self.ps_table = []
        self.param_ps_dict = {}
        self.tasks_table = []

    @classmethod
    def dump(cls, path):
        with open(path, 'wb') as f:
            pickle.dump(cls._instance, f)

    @classmethod
    def load(cls, path):
        with open(path, 'rb') as f:
            cls._instance = pickle.load(f)

    def dumps(self):
        ps_str = ",\n".join([ps.dumps() for ps in self.ps_table])
        task_str = ",\n".join([task.dumps() for task in self.tasks_table])
        return "PS: [\n%s\n],\nTasks: [\n%s\n]\n" % (ps_str, task_str)


if __name__ == "__main__":
    import sys

    if len(sys.argv) == 2:
        t = Tables.load(sys.argv[1])
        print(t.dumps())
    else:
        sys.stderr.write("[Error] invalid number of arguments\n")
        sys.stderr.write("  Usage: python %s <pickle file>\n")
        sys.stderr.write("    it will print the data to stdout\n")
        raise RuntimeError("Invalid number of arguments")
