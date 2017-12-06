import sys,random
from searcher.server import Server
from searcher.parameter_set import ParameterSet
from searcher.tables import Tables

class Searcher:

    def __init__(self,n):
        self.n = n

    def create_initial_runs(self):
        for i in range(self.n):
            ps = ParameterSet.find_or_create((i,))
            ps.create_runs_upto(1)

    def restart(self):
        pass


if len(sys.argv) != 2 and len(sys.argv) != 3:
    sys.stderr.write(str(sys.argv))
    sys.stderr.write("invalid number of argument\n")
    args = ["command_file_path", "[table_dump]"]
    sys.stderr.write("Usage: python %s %s\n" % (__file__, " ".join(args)))
    raise RuntimeError("invalid number of arguments")

cmd_file_path = sys.argv[1]
commands = []

with open(cmd_file_path) as f:
    commands = f.readlines()

s = Searcher(len(commands))

def map_point_to_cmd(point, seed):
    cmd = commands[point[0]]
    return cmd.rstrip()

if len(sys.argv) == 2:
    s.create_initial_runs()
else:
    s.restart()

Server.loop( map_point_to_cmd )

if all([ps.is_finished() for ps in ParameterSet.all()]):
    sys.stderr.write("DONE\n")
else:
    sys.stderr.write("There are unfinished tasks. Writing data to table.msgpack\n")
    Tables.pack("table.msgpack")

