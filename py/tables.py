import setting
import parameter_set
import run


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

