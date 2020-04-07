import unittest
from caravan.tables import Tables
from caravan.parameter_set import ParameterSet
from caravan.simulator import Simulator


class ParameterSetTest(unittest.TestCase):
    def setUp(self):
        self.t = Tables.get()
        self.t.clear()
        self.sim = Simulator.create("echo")

    def test_ps(self):
        param = {"p1":1, "p2":2}
        ps = self.sim.find_or_create_parameter_set(param)
        self.assertEqual(ps.id(), 0)
        self.assertEqual(ps.v(), param)
        self.assertEqual(ps.runs(), [])
        self.assertEqual(ps.simulator(), self.sim)
        self.assertEqual(ParameterSet.all(), [ps])
        self.assertEqual(ParameterSet.find(0), ps)
        self.assertEqual(self.sim.find_parameter_set(param), ps)
        self.assertEqual(ps.to_dict(), {"id":0,"sim_id":0,"params":param,"run_ids":[]})

        # second PS
        param2 = {"p1":2, "p2":3}
        ps2 = self.sim.find_or_create_parameter_set(param2)
        self.assertEqual(ps2.id(), 1)
        self.assertEqual(ps2.v(), param2)
        self.assertEqual(ParameterSet.all(), [ps,ps2])

        # duplicate PS
        self.assertEqual(self.sim.find_or_create_parameter_set(param), ps)
        self.assertEqual(len(ParameterSet.all()), 2)

    def test_create_runs(self):
        ps = self.sim.find_or_create_parameter_set({"foo": "bar"})
        ps.create_runs_upto(3)
        self.assertEqual(len(ps.runs()), 3)
        self.assertEqual([r.id() for r in ps.runs()], [0,1,2])
        ps.create_runs_upto(3)
        self.assertEqual(len(ps.runs()), 3)
        ps.create_runs_upto(5)
        self.assertEqual(len(ps.runs()), 5)

    def test_is_finished(self):
        ps = self.sim.find_or_create_parameter_set({"foo": "bar"})
        self.assertEqual(ps.is_finished(), True)
        ps.create_runs_upto(2)
        self.assertEqual(ps.is_finished(), False)
        self.assertEqual(ps.finished_runs(), [])
        ps.runs()[0].store_result({"o1":1}, 0, 1, 1000, 2000)
        self.assertEqual(ps.is_finished(), False)
        self.assertEqual([r.id() for r in ps.finished_runs()], [0])
        ps.runs()[1].store_result({"o1":1}, 0, 2, 1000, 2000)
        self.assertEqual(ps.is_finished(), True)
        self.assertEqual([r.id() for r in ps.finished_runs()], [0,1])

    def test_outputs(self):
        ps = self.sim.find_or_create_parameter_set({"foo": "bar"})
        ps.create_runs_upto(2)
        self.assertEqual(ps.outputs(), [])
        for (i,r) in enumerate(ps.runs()):
            r.store_result( {"i":i}, 0, i, 0, 10)
        self.assertEqual(len(ps.finished_runs()), 2)
        self.assertEqual(ps.outputs(), [{"i":0}, {"i":1}])

    def test_find(self):
        sim2 = Simulator.create("echo")
        self.assertEqual(sim2.id(), 1)
        ps1 = self.sim.find_or_create_parameter_set({"foo": "bar"})
        self.assertEqual(self.sim.parameter_sets(), [ps1])
        ps1.create_runs_upto(2)
        ps2 = sim2.find_or_create_parameter_set({"foo": "bar"})
        self.assertEqual(sim2.parameter_sets(), [ps2])
        ps2.create_runs_upto(2)
        self.assertEqual([r.id() for r in ps1.runs()], [0,1])
        self.assertEqual([r.id() for r in ps2.runs()], [2,3])
        self.assertEqual([r.id() for r in ParameterSet.all()], [0,1])
        self.assertEqual(ParameterSet.find(1), ps2)

if __name__ == '__main__':
    unittest.main()
