import unittest, os, sys, struct
import tempfile
import subprocess


def eprint(*s):
    print(*s, file=sys.stderr, flush=True)


class BenchmarkSamplesTest(unittest.TestCase):
    def setUp(self):
        self.caravan_dir = os.path.abspath(os.path.dirname(__file__) + "/..")

    def assert_task_period(self, task, expected_start_at, expected_finish_at, delta=0.4):
        if expected_start_at is not None:
            self.assertAlmostEqual(task["start_at"] / 1000, expected_start_at, delta=delta)
        if expected_finish_at is not None:
            self.assertAlmostEqual(task["finish_at"] / 1000, expected_finish_at, delta=delta)

    def test_01(self):
        script = self.caravan_dir + "/samples/benchmark/run_bench1.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.bin"))

    def test_02(self):
        script = self.caravan_dir + "/samples/benchmark/run_bench2.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.bin"))

    def test_03(self):
        script = self.caravan_dir + "/samples/benchmark/run_bench3.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.bin"))

    def test_01_abort_resume(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            script = self.caravan_dir + "/samples/benchmark/run_bench1_abort.sh"
            subprocess.run([script], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.bin"))
            self.assertTrue(os.path.exists(tmpdir + "/table.pickle"))
            os.remove(tmpdir + "/tasks.bin")
            script2 = self.caravan_dir + "/samples/benchmark/run_bench1_resume.sh"
            subprocess.run([script2], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.bin"))

