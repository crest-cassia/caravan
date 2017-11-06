import unittest
import setting
import run
import tables


class TestRun(unittest.TestCase):

    def setUp(self):
        setting.num_outputs = 3
        setting.num_inputs = 4
        tables.clear()

    def test_run(self):
        r = run.Run(1234, 104, 5678)
        self.assertEqual(r.id,1234)
        self.assertEqual(r.ps_id,104)
        self.assertEqual(r.seed,5678)
        self.assertEqual(r.is_finished(),False)
        r.store_result( [1.0, 2.0, 3.0], 3, 111, 222)
        self.assertTrue(r.is_finished())

    def test_pack_unpack(self):
        r = run.Run(1234, 104, 5678)
        r.store_result( [1.0, 2.0, 3.0], 3, 111, 222)
        bytes = r.pack_binary()
        r2 = run.Run.unpack_binary(bytes)
        self.assertEqual(r.id,r2.id)

if __name__ == '__main__':
    unittest.main()

