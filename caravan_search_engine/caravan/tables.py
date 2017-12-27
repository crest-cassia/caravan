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
        self.ps_table = []
        self.runs_table = []

    def clear(self):
        self.ps_table = []
        self.runs_table = []

    @classmethod
    def pack(cls,path):
        import msgpack
        t = cls.get()
        ps_dict = [ps.to_dict() for ps in t.ps_table]
        run_dict = [r.to_dict() for r in t.runs_table]
        obj = {"parameter_sets": ps_dict, "runs": run_dict}
        with open(path, 'wb') as f:
            msgpack.pack(obj, f, use_bin_type=True)
            f.flush()

    @classmethod
    def unpack(cls,path):
        import msgpack
        from .parameter_set import ParameterSet
        from .run import Run
        t = cls.get()
        t.clear()
        with open(path, 'rb') as f:
            obj = msgpack.unpack(f, encoding='utf-8')
            t.ps_table = [ ParameterSet.new_from_dict(o) for o in obj["parameter_sets"] ]
            t.runs_table = [ Run.new_from_dict(o) for o in obj["runs"] ]
        return t

    def dumps(self):
        ps_str = ",\n".join( [ ps.dumps() for ps in self.ps_table ])
        return "[\n%s\n]\n" % ps_str

if __name__ == "__main__":
    import sys
    if len(sys.argv) == 2:
        t = Tables.unpack(sys.argv[1])
        print( t.dumps() )
    else:
        sys.stderr.write("[Error] invalid number of arguments\n")
        sys.stderr.write("  Usage: python %s <msgpack file>\n")
        sys.stderr.write("    it will print the data to stdout\n")
        raise RuntimeError("Invalid number of arguments")

