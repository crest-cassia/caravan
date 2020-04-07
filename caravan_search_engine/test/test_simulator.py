import unittest
from caravan.simulator import Simulator
from caravan.tables import Tables

class SimulatorTest(unittest.TestCase):
    def setUp(self):
        self.t = Tables.get()
        self.t.clear()

    def test_create(self):
        sim = Simulator.create("~/my_simulator.out")
        self.assertEqual( sim.id(), 0 )
        self.assertEqual( sim.command(), "~/my_simulator.out" )
        self.assertEqual( len(Simulator.all()), 1 )
        self.assertEqual( sim, Simulator.find(0) )

        sim2 = Simulator.create("~/sim2.out")
        self.assertEqual( sim2.id(), 1 )
        self.assertEqual( len(Simulator.all()), 2 )
        self.assertEqual( sim2, Simulator.find(1) )

