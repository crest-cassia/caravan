import search_engine
import server

def map_point_to_cmd( point, seed ):
    strs = [ str(x) for x in point ]
    return "echo %s %d" % (" ".join(strs), seed)

ranges = ( range(0,3), range(3,5) )
searcher = search_engine.SearchEngine( ranges )
srv = server.Server( searcher, map_point_to_cmd )
srv.run()

