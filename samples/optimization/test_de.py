import sys
from searcher.server import Server
from searcher.search_engines.de_optimizer.de_optimizer import DE_Optimizer

def main():
    def map_point_to_cmd(point, seed):
        v = (point[0]-1.0)**2 + (point[1]-2.0)**2
        cmd = "bash -c 'echo %f > _results.txt'" % v
        return cmd

    domains = [
            (-10, 10),
            (-10, 10)
            ]


    de = DE_Optimizer( domains, n=30, f=0.8, cr=0.9, t_max=100, rand_seed=1234 )

    def print_logs():
        sys.stderr.write("t=%d  %s, %f, %f\n" % (de.t, repr(de.best_point), de.best_f, de._average_f() ) )
    de.on_each_generation = print_logs
    de.generate_initial_runs()
    Server.loop( map_point_to_cmd )

main()

