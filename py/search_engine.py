import setting
import tables
import parameter_set
import run


def create_initial_runs():
    points = [(0,1,2),(3,4,5)]
    for p in points:
        ps = parameter_set.ParameterSet.find_or_create(p)
        ps.create_runs_upto(3)


