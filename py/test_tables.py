import unittest
import tables
import parameter_set


class TestTables(unittest.TestCase):

    def setUp(self):
        tables.clear()

    def test_dump_empty(self):
        path = "test.dmp"
        tables.dump(path)
        import os.path
        self.assertTrue( os.path.exists(path) )

        tables.load(path)
        self.assertEqual( len(tables.ps_table), 0 )
        self.assertEqual( len(tables.ps_point_table), 0 )
        os.remove(path)

    def test_dump(self):

        ps = parameter_set.ParameterSet.find_or_create((0,1,2,3))
        runs = ps.create_runs_upto(3)
        runs[0].store_result([1.0, 2.0, 3.0], 3, 111, 222)
        ps = parameter_set.ParameterSet.find_or_create((4,5,6,7))
        self.assertEqual( len(tables.ps_table), 2 )
        runs = ps.create_runs_upto(3)
        runs[2].store_result([1.0, 2.0, 3.0], 3, 111, 222)
        self.assertEqual( len(tables.runs_table), 6 )

        path = "test.dmp"
        tables.dump(path)
        tables.clear()
        tables.load(path)
        self.assertEqual( len(tables.ps_table), 2 )
        self.assertEqual( len(tables.runs_table), 6 )
        self.assertTrue( tables.runs_table[0].is_finished() )
        self.assertTrue( tables.runs_table[5].is_finished() )

