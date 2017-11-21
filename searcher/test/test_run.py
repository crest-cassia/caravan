import unittest
import run
import tables


class TestRun(unittest.TestCase):

    def setUp(self):
        self.t = tables.Tables.get()
        self.t.clear()

    def test_run(self):
        r = run.Run(1234, 104, 5678)
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

if __name__ == '__main__':
    unittest.main()

