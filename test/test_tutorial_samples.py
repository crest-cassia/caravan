import unittest,os,sys,struct,tempfile,subprocess
import msgpack

def work_dir_path(tid, base_dir="."):
    return "{base_dir}/w{d1:04d}/w{d2:07d}".format(base_dir=base_dir, d1=int(tid / 1000), d2=tid)

def load_binary(path):
    with open(path, 'rb') as f:
        b = f.read()
        unpacked = msgpack.unpackb(b, raw=False)
        return {t[0]:t[1] for t in unpacked}


class TutorialSamplesTest(unittest.TestCase):
    def setUp(self):
        self.caravan_dir = os.path.abspath(os.path.dirname(__file__) + "/..")
        self.dt = 30

    def assert_task_period(self, task, expected_start_at, expected_finish_at, delta=0.4):
        if expected_start_at is not None:
            self.assertAlmostEqual(task["start_at"] / 1000, expected_start_at, delta=delta)
        if expected_finish_at is not None:
            self.assertAlmostEqual(task["finish_at"] / 1000, expected_finish_at, delta=delta)

    def assert_complete(self, tasks):
        comp = all( [t['rc']==0 for tid,t in tasks.items()] )
        self.assertTrue(comp)

    def run_sample_and_assert_completion(self, script):
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=self.dt)
            tasks = load_binary(tmpdir + "/tasks.msgpack")
            self.assert_complete(tasks)
            return tasks

    def test_01(self):
        script = self.caravan_dir + "/samples/tutorial/01_minimal_code/run.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=self.dt)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.msgpack"))
            for i in range(10):
                d = work_dir_path(i, base_dir=tmpdir)
                self.assertTrue(os.path.exists(d))
                self.assertTrue(os.path.exists(d + "/out"))

    def test_02(self):
        script = self.caravan_dir + "/samples/tutorial/02_visualizing_tasks/run.sh"
        tasks = self.run_sample_and_assert_completion(script)
        self.assertEqual(len(tasks), 20)
        tmax = max([t["finish_at"] for t in tasks.values()])
        tmin = min([t["start_at"] for t in tasks.values()])
        self.assertLessEqual((tmax-tmin)/1000, 16)

    def test_03(self):
        script = self.caravan_dir + "/samples/tutorial/03_defining_callbacks/run.sh"
        tasks = self.run_sample_and_assert_completion(script)
        self.assertEqual(len(tasks), 12)
        # tasks 6 - 7 are executed t=[1,2]
        for i in range(6, 8):
            t = tasks[i]
            self.assert_task_period(t, 1, 2)
        # tasks 8 - 9 are executed t=[2,4]
        for i in range(8, 10):
            t = tasks[i]
            self.assert_task_period(t, 2, 4)
        # tasks 10 - 11 are executed t=[4,7]
        for i in range(10, 12):
            t = tasks[i]
            self.assert_task_period(t, 3, 6)

    def test_04_1(self):
        script = self.caravan_dir + "/samples/tutorial/04_async_await/run1.sh"
        tasks = self.run_sample_and_assert_completion(script)
        self.assert_task_period(tasks[0], 0, 1)
        self.assert_task_period(tasks[1], 1, 3)
        self.assert_task_period(tasks[2], 3, 6)

    def test_04_2(self):
        script = self.caravan_dir + "/samples/tutorial/04_async_await/run2.sh"
        tasks = self.run_sample_and_assert_completion(script)
        self.assertEqual(5, len(tasks))

    def test_04_3(self):
        script = self.caravan_dir + "/samples/tutorial/04_async_await/run3.sh"
        tasks = self.run_sample_and_assert_completion(script)
        f = [t["finish_at"] for t in tasks.values()]
        self.assertAlmostEqual(max(f) / 1000, 7, delta=0.4)

    def test_05_1(self):
        script = self.caravan_dir + "/samples/tutorial/05_getting_results/run1.sh"
        tasks = self.run_sample_and_assert_completion(script)
        self.assertEqual(tuple(tasks[0]["output"]), (1.0, 2.0, 3.0))

    def test_05_2(self):
        script = self.caravan_dir + "/samples/tutorial/05_getting_results/run2.sh"
        tasks = self.run_sample_and_assert_completion(script)
        for i in range(4):
            self.assertEqual(tasks[i]["output"], i)

    def test_05_3(self):
        script = self.caravan_dir + "/samples/tutorial/05_getting_results/run3.sh"
        tasks = self.run_sample_and_assert_completion(script)
        self.assertEqual(tasks[0]['output'], {"foo":1,"bar":2,"baz":3})

    def test_06_1(self):
        script = self.caravan_dir + "/samples/tutorial/06_ps_run/run1.sh"
        tasks = self.run_sample_and_assert_completion(script)
        self.assertEqual(len(tasks), 10)

    def test_06_2(self):
        script = self.caravan_dir + "/samples/tutorial/06_ps_run/run2.sh"
        tasks = self.run_sample_and_assert_completion(script)

    def test_06_3(self):
        script = self.caravan_dir + "/samples/tutorial/06_ps_run/run3.sh"
        tasks = self.run_sample_and_assert_completion(script)

    def test_07_1(self):
        script = self.caravan_dir + "/samples/tutorial/07_testing_with_a_stub/run1.sh"
        tasks = self.run_sample_and_assert_completion(script)

    def test_07_2(self):
        script = self.caravan_dir + "/samples/tutorial/07_testing_with_a_stub/run2.sh"
        tasks = self.run_sample_and_assert_completion(script)

    def test_08_1(self):
        script = self.caravan_dir + "/samples/tutorial/08_serialize/run1.sh"
        tasks = self.run_sample_and_assert_completion(script)

    def test_08_2(self):
        script = self.caravan_dir + "/samples/tutorial/08_serialize/run2.sh"
        tasks = self.run_sample_and_assert_completion(script)
