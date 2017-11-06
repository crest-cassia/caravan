import unittest
import tables
import parameter_set
import setting


class ParameterSetTest(unittest.TestCase):

    def setUp(self):
        setting.num_outputs = 3
        setting.num_inputs = 4
        tables.clear()

    def test_ps(self):
        ps = parameter_set.ParameterSet(500, (2, 3, 4, 5))
        self.assertEqual(ps.id,500)
        self.assertEqual(ps.point,(2,3,4,5))
        self.assertEqual(ps.run_ids,[])

    def test_pack_unpack(self):
        ps = parameter_set.ParameterSet(500, (2, 3, 4, 5))
        bytes = ps.pack_binary()
        ps2 = parameter_set.ParameterSet.unpack_binary(bytes)
        self.assertEqual(ps.id,ps2.id)
        self.assertEqual(ps.point,ps2.point)

    def test_create(self):
        ps = parameter_set.ParameterSet.find_or_create((0, 1, 2, 3))
        self.assertEqual(ps.id,0)
        self.assertEqual(ps.point,(0,1,2,3))
        self.assertEqual(len(tables.ps_table),1)
        self.assertEqual(len(tables.ps_point_table),1)
        ps2 = parameter_set.ParameterSet.find_or_create((3, 4, 5, 6))
        self.assertEqual(len(tables.ps_table),2)
        self.assertEqual(len(tables.ps_point_table),2)
        self.assertEqual(tables.ps_point_table[(3,4,5,6)], ps2)

        ps3 = parameter_set.ParameterSet.find_or_create((0, 1, 2, 3))
        self.assertEqual(ps,ps3)
        self.assertEqual(len(tables.ps_table), 2)
        self.assertEqual(len(tables.ps_point_table), 2)

    def test_create_runs(self):
        ps = parameter_set.ParameterSet.find_or_create((0, 1, 2, 3))
        runs = ps.create_runs_upto(3)
        self.assertEqual( [r.id for r in runs], [0, 1, 2] )
        self.assertEqual( [r.seed for r in runs], [0,1,2] )
        ps2 = parameter_set.ParameterSet.find_or_create((0, 1, 3, 4))
        runs = ps2.create_runs_upto(3)
        self.assertEqual( [r.id for r in runs], [3, 4, 5] )
        self.assertEqual( [r.seed for r in runs], [0,1,2] )

    def test_is_finished(self):
        ps = parameter_set.ParameterSet.find_or_create((0, 1, 2, 3))
        self.assertEqual( ps.is_finished(), True )
        runs = ps.create_runs_upto(1)
        self.assertFalse( ps.is_finished() )
        self.assertEqual( len(ps.finished_runs()), 0 )
        runs[0].store_result( [1.0, 2.0, 3.0], 3, 111, 222)
        self.assertTrue( ps.is_finished() )
        self.assertEqual( len(ps.finished_runs()), 1 )

    def test_averaged_result(self):
        ps = parameter_set.ParameterSet.find_or_create((0, 1, 2, 3))
        runs = ps.create_runs_upto(3)
        self.assertEqual( ps.averaged_result(), [None] * setting.num_outputs )
        for (i,r) in enumerate(runs):
            r.store_result([1.0+i, 2.0+i, 3.0+1], 3, 111, 222)
        self.assertEqual( ps.averaged_result(), [2.0, 3.0, 4.0] )


if __name__ == '__main__':
    unittest.main()
