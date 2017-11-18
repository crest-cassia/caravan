import unittest
import tables
from parameter_set import ParameterSet
import os.path


class TestTables(unittest.TestCase):

    def setUp(self):
        tables.clear()
        self.dump_path = "test.dmp"
        self.msgpack_path = "test.msg"
        self._clean()

    def tearDown(self):
        self._clean()
        tables.clear()

    def _clean(self):
        if os.path.exists(self.dump_path):
            os.remove(self.dump_path)
        if os.path.exists(self.msgpack_path):
            os.remove(self.msgpack_path)

    def test_dump_empty(self):
        path = self.dump_path
        tables.dump(path)
        self.assertTrue( os.path.exists(path) )
        tables.load(path)
        self.assertEqual( len(tables.ps_table), 0 )
        self.assertEqual( len(tables.ps_point_table), 0 )

    def test_dump(self):
        ps = ParameterSet.find_or_create((0,1,2,3))
        runs = ps.create_runs_upto(3)
        runs[0].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        ps = ParameterSet.find_or_create((4,5,6,7))
        self.assertEqual( len(tables.ps_table), 2 )
        runs = ps.create_runs_upto(3)
        runs[2].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertEqual( len(tables.runs_table), 6 )

        path = self.dump_path
        tables.dump(path)
        self.assertTrue( os.path.exists(path) )
        tables.clear()
        tables.load(path)
        self.assertEqual( len(tables.ps_table), 2 )
        self.assertEqual( len(tables.runs_table), 6 )
        self.assertTrue( tables.runs_table[0].is_finished() )
        self.assertTrue( tables.runs_table[5].is_finished() )

    def test_pack_unpack(self):
        ps = ParameterSet.find_or_create((0,1,2,3))
        runs = ps.create_runs_upto(3)
        runs[0].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        ps = ParameterSet.find_or_create((4,5,6,7))
        self.assertEqual( len(tables.ps_table), 2 )
        runs = ps.create_runs_upto(3)
        runs[2].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertEqual( len(tables.runs_table), 6 )

        tables.pack( self.msgpack_path )
        self.assertTrue( os.path.exists(self.msgpack_path) )
        tables.clear()
        tables.unpack( self.msgpack_path )
        self.assertEqual( len(tables.ps_table), 2 )
        self.assertEqual( len(tables.runs_table), 6 )
        self.assertEqual( len(tables.ps_point_table), 2 )
        self.assertTrue( tables.runs_table[0].is_finished() )
        self.assertTrue( tables.runs_table[5].is_finished() )

