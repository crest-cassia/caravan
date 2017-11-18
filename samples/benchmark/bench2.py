import sys,random

if len(sys.argv) != 7:
    sys.stderr.write(str(sys.argv))
    sys.stderr.write("invalid number of argument\n")
    args = ["num_max_job", "num_min_job", "iteration",
            "num_jobs_per_gen", "sleep_mu", "sleep_sigma"]
    sys.stderr.write("Usage: python %s %s\n" % (__file__, " ".join(args)))
    raise RuntimeError("invalid number of arguments")

num_max_job = int(sys.argv[1])
num_min_job = int(sys.argv[2])
iteration = float(sys.argv[3])
num_jobs_per_gen = int(sys.argv[4])
sleep_mu = float(sys.argv[5])
sleep_sigma = float(sys.argv[6])
sleep_range = ( sleep_mu - sleep_sigma, sleep_mu + sleep_sigma )

#sys.stderr.write(str([num_static_jobs, num_dynamic_jobs, job_gen_prob, num_jobs_per_gen, sleep_range]))

random.seed(1234)
ps_count = 0
num_running = 0

def print_tasks(num):
    global ps_count, num_running, num_todo
    for i in range(num):
        t = random.uniform( sleep_range[0], sleep_range[1] )
        sys.stdout.write("%d sleep %f\n" % (ps_count,t))
        ps_count += 1
        num_running += 1
    sys.stdout.write("\n")

print_tasks(num_max_job)
while num_running > 0:
    line = sys.stdin.readline()
    # sys.stderr.write("[debug] %s\n" % line)
    if not line: break
    line = line.rstrip()
    if not line: break
    l = line.split(' ')
    rid,rc,place_id,start_at,finish_at = [ int(x) for x in l[:5] ]
    num_running -= 1
    if num_running == num_min_job and iteration > 0:
        print_tasks(num_jobs_per_gen)
        iteration -= 1
    else:
        print_tasks(0)

