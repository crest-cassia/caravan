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
    setting.command = config['command']
    f.close()

max_submitted_run_id = 0

def _submit(run):
    global max_submitted_run_id
    s_point = " ".join( [str(x) for x in run.parameter_set().point] )
    out = "%d %s %d %s %d\n" % (run.id, setting.command, run.id, s_point, run.seed)
    sys.stdout.write(out)
    max_submitted_run_id = len(tables.runs_table)

def submit_new_runs():
    global max_submitted_run_id
    un_submitted = tables.runs_table[max_submitted_run_id:]
    for r in un_submitted:
        if not r.is_finished():
            _submit(r)

def _parse_line(line):
    l = line.split(' ')
    rid,rc,place_id,start_at,finish_at = [ int(x) for x in l[:5] ]
    results = [ float(x) for x in l[5:] ]
    r = tables.runs_table[rid]
    r.store_result(results,place_id,start_at,finish_at)
    return r

def receive_finished_run():
    line = sys.stdin.readline()
    line = line.rstrip()
    if not line:
        return None
    return _parse_line(line)


load_setting('config.json')

se.create_initial_runs()
submit_new_runs()

while True:
    r = receive_finished_run()
    if r:
        ps = r.parameter_set()
        if ps.is_finished():
            se.on_parameter_set_finished(ps)
            submit_new_runs()
    else:
        break

tables.dump('table.dmp')

