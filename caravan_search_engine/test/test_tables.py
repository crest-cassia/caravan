import unittest
import os.path
from caravan.tables import Tables
from caravan.simulator import Simulator
from caravan.parameter_set import ParameterSet
from caravan.task import Task


class TestTables(unittest.TestCase):
    def setUp(self):
        self.t = Tables.get()
        self.t.clear()
        self.dump_path = "test.pkl"
        self._clean()

    def tearDown(self):
        self._clean()
        self.t.clear()

    def _clean(self):
        if os.path.exists(self.dump_path):
            os.remove(self.dump_path)

    def test_dump_empty(self):
        path = self.dump_path
        Tables.dump(path)
        self.assertTrue(os.path.exists(path))
        Tables.load(path)
        self.assertEqual(len(self.t.ps_table), 0)

    def test_dump(self):
        sim = Simulator.create("~/my_simulator")
        ps = sim.find_or_create_parameter_set({"p1":0, "p2":1})
        runs = ps.create_runs_upto(3)
        runs[0].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        ps2 = sim.find_or_create_parameter_set({"p1":2, "p2":3})
        self.assertEqual(len(ParameterSet.all()), 2)
        runs = ps2.create_runs_upto(3)
        runs[2].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertEqual(len(self.t.tasks_table), 6)

        path = self.dump_path
        Tables.dump(path)
        self.assertTrue(os.path.exists(path))
        self.t.clear()
        Tables.load(path)
        self.t = Tables.get()
        self.assertEqual(len(ParameterSet.all()), 2)
        self.assertEqual(len(Task.all()), 6)
        self.assertTrue(Task.find(0).is_finished())
        self.assertTrue(Task.find(5).is_finished())
