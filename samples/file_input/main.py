import sys
from caravan.server import Server
from caravan.task import Task

if len(sys.argv) != 2:
    sys.stderr.write("Usage: python <command_file_path>\n")
    raise RuntimeError("invalid number of arguments")

with Server.start():
    with open(sys.argv[1]) as f:
        for line in f:
            Task.create(line.rstrip())

sys.stderr.write("DONE\n")
