import unittest, os, sys, struct
import tempfile
import subprocess


def eprint(*s):
    print(*s, file=sys.stderr, flush=True)


class OptimizationSamplesTest(unittest.TestCase):
    def setUp(self):
        self.caravan_dir = os.path.abspath(os.path.dirname(__file__) + "/..")

    def test_01(self):
        script = self.caravan_dir + "/samples/optimization/run_opt.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.bin"))
            # assert output of the optimization
            self.assertTrue(os.path.exists(tmpdir + "/opt_log.txt"))
            with open(tmpdir + "/opt_log.txt") as f:
                best_f = float(f.readlines()[-1].split()[-2])
                self.assertLess(best_f, 10.0)

