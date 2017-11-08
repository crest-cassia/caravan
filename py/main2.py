import search_engine
import server
from search_engines.test_searcher import TestSearcher as Engine
import tables
import sys

def map_point_to_cmd( point, seed ):
    strs = [ str(x) for x in point ]
    return "echo %s %d" % (" ".join(strs), seed)

ranges = ( range(0,3), range(3,5) )
searcher = Engine( ranges, num_runs = 2 )
srv = server.Server( searcher, map_point_to_cmd )
srv.run()

sys.stderr.write( tables.dumps() )
