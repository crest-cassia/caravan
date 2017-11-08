from parameter_set import ParameterSet
from run import Run
import pickle

ps_table = []
ps_point_table = {}  # find PS from points
runs_table = []

def clear():
    global ps_table
    global ps_point_table
    global runs_table
    ps_table = []
    ps_point_table = {}
    runs_table = []

def dump(path):
    global ps_table
    global ps_point_table
    global runs_table

    obj = {"ps_table": ps_table, "ps_point_table": ps_point_table, "runs_table": runs_table}
    with open(path, 'wb') as f:
        pickle.dump(obj, f)

def load(path):
    global ps_table
    global ps_point_table
    global runs_table
    clear()
    with open(path, 'rb') as f:
        obj = pickle.load(f)
        ps_table = obj["ps_table"]
        ps_point_table = obj["ps_point_table"]
        runs_table = obj["runs_table"]

def pack(path):
    import msgpack
    ps_dict = [ps.to_dict() for ps in ps_table]
    run_dict = [r.to_dict() for r in runs_table]
    obj = {"parameter_sets": ps_dict, "runs": run_dict}
    with open(path, 'wb') as f:
        msgpack.pack(obj, f, use_bin_type=True)
        f.flush()

def unpack(path):
    import msgpack
    global ps_table
    global ps_point_table
    global runs_table
    clear()
    with open(path, 'rb') as f:
        obj = msgpack.unpack(f, encoding='utf-8')
        #import pdb; pdb.set_trace()
        ps_table = [ ParameterSet.new_from_dict(o) for o in obj["parameter_sets"] ]
        runs_table = [ Run.new_from_dict(o) for o in obj["runs"] ]
        for ps in ps_table:
            ps_point_table[ ps.point ] = ps

def dumps():
    ps_str = ",\n".join( [ ps.dumps() for ps in ps_table ])
    return "[\n%s\n]\n" % ps_str

if __name__ == "__main__":
    import sys
    if len(sys.argv) == 2:
        load(sys.argv[1])
        print( dumps() )
    elif len(sys.argv) == 3:
        load(sys.argv[1])
        pack(sys.argv[2])
    else:
        sys.stderr.write("[Error] invalid number of arguments\n")
        sys.stderr.write("  Usage: python %s <pickle file> [msgpack file]\n")
        sys.stderr.write("    if [msgpack] is not given, it will print the data to stdout\n")
        sys.stderr.write("    if [msgpack] is given, it will pack the data in msgpack format\n")
        raise RuntimeError("Invalid number of arguments")

