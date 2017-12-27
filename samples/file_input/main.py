import sys,random
from caravan.server import Server
from caravan.parameter_set import ParameterSet
from caravan.tables import Tables

class Searcher:

    def __init__(self):
        pass

    def create_initial_runs(self, cmd_file):
        with open(cmd_file) as f:
            for line in f:
                cmd = line.rstrip()
                if not cmd: break
                ps = ParameterSet.create(cmd)
                ps.create_runs_upto(1)

if len(sys.argv) != 2 and len(sys.argv) != 3:
    sys.stderr.write(str(sys.argv))
    sys.stderr.write("invalid number of argument\n")
    args = ["command_file_path", "[table_dump]"]
    sys.stderr.write("Usage: python %s %s\n" % (__file__, " ".join(args)))
    raise RuntimeError("invalid number of arguments")

cmd_file_path = sys.argv[1]

s = Searcher()

if len(sys.argv) == 2:
    s.create_initial_runs(sys.argv[1])
else:
    Tables.unpack(sys.argv[2])

def map_params_to_cmd(params, seed):
    return params

Server.loop( map_params_to_cmd )

if all([ps.is_finished() for ps in ParameterSet.all()]):
    sys.stderr.write("DONE\n")
else:
    sys.stderr.write("There are unfinished tasks. Writing data to table.msgpack\n")
    Tables.pack("table.msgpack")

