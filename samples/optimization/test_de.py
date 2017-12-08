import sys
from caravan.server import Server
from caravan.search_engines.de_optimizer.de_optimizer import DE_Optimizer

def main(n,f,cr,tmax):
    def map_point_to_cmd(point, seed):
        v = (point[0]-1.0)**2 + (point[1]-2.0)**2
        cmd = "bash -c 'echo %f > _results.txt'" % v
        return cmd

    domains = [
            (-1000, 1000),
            (-1000, 1000)
            ]

    de = DE_Optimizer( domains, n=n, f=f, cr=cr, t_max=tmax, rand_seed=1234 )

    f = open("opt_log.txt", "w")
    f.write("### t [best_point] best_f average_f\n")

    def print_logs():
        f.write("%d %s %f %f\n" % (de.t, repr(de.best_point), de.best_f, de._average_f() ) )
    de.on_each_generation = print_logs
    de.generate_initial_runs()
    Server.loop( map_point_to_cmd )
    f.close()

if len(sys.argv) != 5:
    sys.stderr.write("invalid number of arguments\n")
    sys.stderr.write("[Usage] python -u %s <n> <f> <cr> <tmax>\n" % __file__)
else:
    n = int(sys.argv[1])
    f = float(sys.argv[2])
    cr = float(sys.argv[3])
    tmax = int(sys.argv[4])
    sys.stderr.write("optimization parameters are n=%d, f=%f, cr=%f, tmax=%d\n" % (n,f,cr,tmax))
    main(n,f,cr,tmax)

