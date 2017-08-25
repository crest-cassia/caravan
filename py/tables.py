import setting
import parameter_set
import run
import struct


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

    out = open(path, 'wb')

    # write "num_inputs", "num_outputs", "num_ps"
    bytes = struct.pack(">qqq", setting.num_inputs, setting.num_outputs, len(ps_table))
    out.write(bytes)
    # write parameter_sets
    for ps in ps_table:
        out.write( ps.pack_binary() )
    # write "num_runs
    bytes = struct.pack(">q", len(runs_table))
    out.write(bytes)
    # write runs
    for r in runs_table:
        out.write( r.pack_binary() )
    out.close()

def load(path):
    global ps_table
    global ps_point_table
    global runs_table

    clear()
    infile = open(path, 'rb')

    # read "num_inputs", "num_outputs", "num_ps"
    bytes = infile.read(24)
    num_inputs, num_outputs, num_ps = struct.unpack(">qqq", bytes)
    setting.num_inputs = num_inputs
    setting.num_outputs = num_outputs
    # read parameter_sets
    byte_size_ps = parameter_set.ParameterSet.byte_size()
    for i in range(num_ps):
        bytes = infile.read(byte_size_ps)
        ps = parameter_set.ParameterSet.unpack_binary(bytes)
        assert len(ps_table) == ps.id
        ps_table.append(ps)
        ps_point_table[ ps.point ] = ps
    # read runs
    bytes = infile.read(8)
    num_run = struct.unpack(">q", bytes)[0]
    bytes_size_run = run.Run.byte_size()
    for i in range(num_run):
        bytes = infile.read(bytes_size_run)
        r = run.Run.unpack_binary(bytes)
        assert len(runs_table) == r.id
        runs_table.append(r)
    infile.close()


