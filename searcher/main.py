import server
from search_engines.comprehensive_searcher import ComprehensiveSearcher as Engine

def map_point_to_cmd( point, seed ):
    strs = [ str(x) for x in point ]
    return "echo %s %d" % (" ".join(strs), seed)

ranges = ( range(0,3), range(3,5) )
se = Engine( ranges, num_runs = 2 )
w = server.Server( map_point_to_cmd )
se.create_initial_runs(w)
w.loop()

