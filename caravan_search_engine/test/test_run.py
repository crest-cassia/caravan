import unittest
from caravan.run import Run
from caravan.tables import Tables
from caravan.parameter_set import ParameterSet

class TestRun(unittest.TestCase):

    def setUp(self):
        self.t = Tables.get()
        self.t.clear()

    def test_run(self):
        r = Run(1234, 104, 5678)
        self.assertEqual(r.id,1234)
        self.assertEqual(r.ps_id,104)
        self.assertEqual(r.seed,5678)
        self.assertEqual(r.is_finished(),False)
        r.store_result( [1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertTrue(r.is_finished())
        self.assertEqual( r.rc, 0 )
        self.assertEqual( r.place_id, 3 )
        self.assertEqual( r.start_at, 111 )
        self.assertEqual( r.finish_at, 222 )

    def test_all(self):
        ps = ParameterSet.create((0, 1, 2, 3))
        runs = ps.create_runs_upto(3)
        self.assertEqual( Run.all(), runs )
        ps2 = ParameterSet.create((0, 1, 2, 4))
        runs2 = ps2.create_runs_upto(3)
        self.assertEqual( len(Run.all()), 6 )

    def test_find(self):
        ps = ParameterSet.create((0, 1, 2, 3))
        runs = ps.create_runs_upto(3)
        rid = runs[1].id
        self.assertEqual(rid,1)
        self.assertEqual(Run.find(rid),runs[1])

if __name__ == '__main__':
    unittest.main()

