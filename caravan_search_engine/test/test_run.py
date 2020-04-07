import unittest
from caravan.run import Run
from caravan.tables import Tables
from caravan.simulator import Simulator


class TestRun(unittest.TestCase):
    def setUp(self):
        self.t = Tables.get()
        self.t.clear()
        self.sim = Simulator.create("~/my_simulator")
        self.ps = self.sim.find_or_create_parameter_set({"p1":1})

    def test_run(self):
        r = self.ps.create_runs_upto(1)[0]
        self.assertEqual(r.id(), 0)
        self.assertEqual(r.parameter_set(), self.ps)
        self.assertEqual(r.seed(), 0)
        self.assertEqual(r.is_finished(), False)
        r.store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertTrue(r.is_finished())
        self.assertEqual(r.rc(), 0)
        self.assertEqual(r.rank(), 3)
        self.assertEqual(r.start_at(), 111)
        self.assertEqual(r.finish_at(), 222)
        self.assertEqual(r.output(), [1.0, 2.0, 3.0])

    def test_all_find(self):
        runs = self.ps.create_runs_upto(3)
        self.assertEqual(Run.all(), runs)
        ps2 = self.sim.find_or_create_parameter_set({"p1":2})
        runs2 = ps2.create_runs_upto(3)
        self.assertEqual(len(Run.all()), 6)
        self.assertEqual(Run.find(1), runs[1])
        self.assertEqual(Run.find(4).id(), 4)


if __name__ == '__main__':
    unittest.main()
