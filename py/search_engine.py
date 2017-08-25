import setting
import tables
import parameter_set


def create_initial_runs():
    points = [(0,1,2),(3,4,5)]
    for p in points:
        ps = parameter_set.ParameterSet.find_or_create(p)
        ps.create_runs_upto(3)

def on_parameter_set_finished(finished_ps):
    if finished_ps.point == (0,1,2):
        ps = parameter_set.ParameterSet.find_or_create((6,7,8))
        ps.create_runs_upto(3)

