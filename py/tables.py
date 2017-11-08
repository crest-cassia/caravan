import parameter_set
import run
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

def dumps():
    ps_str = ",\n".join( [ ps.dumps() for ps in ps_table ])
    return "[\n%s\n]\n" % ps_str

