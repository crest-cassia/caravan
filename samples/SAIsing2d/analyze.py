import sys
import os.path
import json

from SALib.analyze import sobol
from SALib.util import read_param_file
import numpy as np

if len(sys.argv) != 4:
    sys.stderr.write("Invalid argument\n")
    sys.stderr.write("  Usage: python %s param.txt ps_ids.txt runs.json\n" % os.path.basename(__file__))
    raise

def parse_output( ps_ids, runs_json ):
    fp = open( runs_json )
    runs = json.load( fp )

    results = []
    lines = open( ps_ids ).readlines()
    for line in lines:
        psid = int(line)
        matched = [ run for run in runs if run["parentPSId"] == psid ]
        result = matched[0]["result"][0]
        results.append( result )
    return np.array( results )

outputs = parse_output( sys.argv[2], sys.argv[3] )
# print( outputs )
problem = read_param_file( sys.argv[1] )
# print( problem )

si = sobol.analyze( problem, outputs, False, print_to_console=True )

