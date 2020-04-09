import unittest,os,sys,struct,tempfile,subprocess
import msgpack


class BenchmarkSamplesTest(unittest.TestCase):
    def setUp(self):
        self.caravan_dir = os.path.abspath(os.path.dirname(__file__) + "/..")

    def _load_binary(self,path):
        with open(path, 'rb') as f:
            b = f.read()
            unpacked = msgpack.unpackb(b, raw=False)
            return {t[0]:t[1] for t in unpacked}

    def _assert_complete(self, tasks):
        comp = all( [t['rc']==0 for tid,t in tasks.items()] )
        self.assertTrue(comp)

    def _run_sample_and_assert_completion(self, script):
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=30)
            tasks = self._load_binary(tmpdir + "/tasks.msgpack")
            self._assert_complete(tasks)
            return tasks

    def test_01(self):
        script = self.caravan_dir + "/samples/benchmark/run_bench1.sh"
        tasks = self._run_sample_and_assert_completion(script)

    def test_02(self):
        script = self.caravan_dir + "/samples/benchmark/run_bench2.sh"
        tasks = self._run_sample_and_assert_completion(script)

    def test_03(self):
        script = self.caravan_dir + "/samples/benchmark/run_bench3.sh"
        tasks = self._run_sample_and_assert_completion(script)

    def test_01_abort_resume(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            script = self.caravan_dir + "/samples/benchmark/run_bench1_abort.sh"
            subprocess.run([script], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.msgpack"))
            self.assertTrue(os.path.exists(tmpdir + "/table.pickle"))
            os.remove(tmpdir + "/tasks.msgpack")
            script2 = self.caravan_dir + "/samples/benchmark/run_bench1_resume.sh"
            subprocess.run([script2], check=True, cwd=tmpdir, timeout=30)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.msgpack"))

