import sys
import json
import setting
import tables
import search_engine as se

def load_setting(config_file):
    f = open(config_file, 'r')
    config = json.load(f)
    setting.num_inputs = config['num_inputs']
    setting.num_outputs = config['num_outputs']
    setting.search_region = config['search_region']
    f.close()

max_submitted_run_id = 0

def _submit(run):
    s_point = " ".join( [str(x) for x in run.parameter_set().point] )
    out = "%d %s %d\n" % (run.id, s_point, run.seed)
    sys.stdout.write(out)

def submit_new_runs():
    un_submitted = tables.runs_table[max_submitted_run_id:]
    for r in un_submitted:
        if not r.is_finished():
            _submit(r)

load_setting('config.json')

se.create_initial_runs()
submit_new_runs()

#line = sys.stdin.readline()
#while line:
#    finished_ps = parse_line(line)
#    if finished_ps:
#        on_parameter_set_finished(finished_ps)
#        submit_new_runs()
#    line = sys.stdin.readline()

