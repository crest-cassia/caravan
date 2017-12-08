import unittest
import pickle
import os.path
from caravan.tables import Tables
from caravan.parameter_set import ParameterSet


class TestTables(unittest.TestCase):

    def setUp(self):
        self.t = Tables.get()
        self.t.clear()
        self.dump_path = "test.pkl"
        self.msgpack_path = "test.msg"
        self._clean()

    def tearDown(self):
        self._clean()
        self.t.clear()

    def _clean(self):
        if os.path.exists(self.dump_path):
            os.remove(self.dump_path)
        if os.path.exists(self.msgpack_path):
            os.remove(self.msgpack_path)

    def test_dump_empty(self):
        path = self.dump_path
        with open(path, 'wb') as f:
            pickle.dump(self.t, f)
            f.flush()
        self.assertTrue( os.path.exists(path) )
        with open(path, 'rb') as f:
            self.t = pickle.load(f)
        self.assertEqual( len(self.t.ps_table), 0 )

    def test_dump(self):
        ps = ParameterSet.create((0,1,2,3))
        runs = ps.create_runs_upto(3)
        runs[0].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        ps = ParameterSet.create((4,5,6,7))
        self.assertEqual( len(self.t.ps_table), 2 )
        runs = ps.create_runs_upto(3)
        runs[2].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertEqual( len(self.t.runs_table), 6 )

        path = self.dump_path
        with open(path, 'wb') as f:
            pickle.dump(self.t, f)
            f.flush()
        self.assertTrue( os.path.exists(path) )
        self.t.clear()
        with open(path, 'rb') as f:
            self.t = pickle.load(f)
        self.assertEqual( len(self.t.ps_table), 2 )
        self.assertEqual( len(self.t.runs_table), 6 )
        self.assertTrue( self.t.runs_table[0].is_finished() )
        self.assertTrue( self.t.runs_table[5].is_finished() )

    def test_pack_unpack(self):
        ps = ParameterSet.create((0,1,2,3))
        runs = ps.create_runs_upto(3)
        runs[0].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        ps = ParameterSet.create((4,5,6,7))
        self.assertEqual( len(self.t.ps_table), 2 )
        runs = ps.create_runs_upto(3)
        runs[2].store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertEqual( len(self.t.runs_table), 6 )

        Tables.pack( self.msgpack_path )
        self.assertTrue( os.path.exists(self.msgpack_path) )
        self.t.clear()
        Tables.unpack( self.msgpack_path )
        self.assertEqual( len(self.t.ps_table), 2 )
        self.assertEqual( len(self.t.runs_table), 6 )
        self.assertTrue( self.t.runs_table[0].is_finished() )
        self.assertTrue( self.t.runs_table[5].is_finished() )

