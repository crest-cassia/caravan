import unittest, os, sys, struct
import tempfile
import subprocess


def eprint(*s):
    print(*s, file=sys.stderr, flush=True)


def work_dir_path(tid, base_dir="."):
    return f"{base_dir}/w{int(tid/1000):04d}/w{tid:07d}"


def load_binary(path):
    tasks = {}
    with open(path, 'rb') as f:
        while True:
            bytes = f.read(48)
            if bytes:
                tid, rc, place_id, start_at, finish_at, n_results = struct.unpack(">6q", bytes)
                results = struct.unpack(f">{n_results:d}d", f.read(8 * n_results))
                t = {"id": tid, "rc": rc, "start_at": start_at, "finish_at": finish_at, "results": results}
                tasks[tid] = t
            else:
                break
    return tasks


class TutorialSamplesTest(unittest.TestCase):
    def setUp(self):
        self.caravan_dir = os.path.abspath(os.path.dirname(__file__) + "/..")
        self.se_module_path = self.caravan_dir + "/caravan_serach_engine"

    def assert_task_period(self, task, expected_start_at, expected_finish_at, delta = 0.2):
        if expected_start_at is not None:
            self.assertAlmostEqual(task["start_at"]/1000, expected_start_at, delta=delta)
        if expected_finish_at is not None:
            self.assertAlmostEqual(task["finish_at"]/1000, expected_finish_at, delta=delta)

    def test_01(self):
        script = self.caravan_dir + "/samples/tutorial/01_minimal_code/run.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=5)
            self.assertTrue(os.path.exists(tmpdir + "/tasks.bin"))
            # assert output files exist
            for i in range(10):
                d = work_dir_path(i, base_dir=tmpdir)
                self.assertTrue(os.path.exists(d))
                self.assertTrue(os.path.exists(d + "/out"))

    def test_02(self):
        script = self.caravan_dir + "/samples/tutorial/02_visualizing_tasks/run.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=15)
            dump_path = tmpdir + "/tasks.bin"
            self.assertTrue(os.path.exists(dump_path))
            # assert task scheduling
            tasks = load_binary(dump_path)
            self.assertEqual(len(tasks), 40)
            dt = tasks[39]["finish_at"] - tasks[0]["start_at"]
            self.assertLessEqual(dt / 1000, 8)

    def test_03(self):
        script = self.caravan_dir + "/samples/tutorial/03_defining_callbacks/run.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=15)
            dump_path = tmpdir + "/tasks.bin"
            self.assertTrue(os.path.exists(dump_path))
            # assert callbacks are executed
            tasks = load_binary(dump_path)
            self.assertEqual(len(tasks), 20)
            # tasks 10 - 13 are executed during t=1~2
            for i in range(10, 14):
                t = tasks[i]
                self.assert_task_period(t, 1, 2)
            # tasks 14 - 16 are executed t=[2,4]
            for i in range(14, 17):
                t = tasks[i]
                self.assert_task_period(t, 2, 4)
            # tasks 17 - 19 are executed t=[4,7]
            for i in range(17, 20):
                t = tasks[i]
                self.assert_task_period(t, 3, 6)

    def test_04_1(self):
        script = self.caravan_dir + "/samples/tutorial/04_async_await/run1.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=15)
            dump_path = tmpdir + "/tasks.bin"
            self.assertTrue(os.path.exists(dump_path))
            # assert awaited tasks
            tasks = load_binary(dump_path)
            self.assert_task_period(tasks[0], 0, 1)
            self.assert_task_period(tasks[1], 1, 3)
            self.assert_task_period(tasks[2], 3, 6)


    def test_04_2(self):
        script = self.caravan_dir + "/samples/tutorial/04_async_await/run2.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=15)
            dump_path = tmpdir + "/tasks.bin"
            self.assertTrue(os.path.exists(dump_path))
            # assert awaited tasks
            tasks = load_binary(dump_path)
            for i in range(0, 5):
                self.assert_task_period(tasks[i], 0, None)
            for i in range(5, 10):
                self.assert_task_period(tasks[i], 3, None)

    def test_04_3(self):
        script = self.caravan_dir + "/samples/tutorial/04_async_await/run3.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=15)
            dump_path = tmpdir + "/tasks.bin"
            self.assertTrue(os.path.exists(dump_path))
            tasks = load_binary(dump_path)
            f = [t["finish_at"] for t in tasks.values()]
            self.assertAlmostEqual(max(f)/1000, 11, delta = 0.2)

    def test_05_1(self):
        script = self.caravan_dir + "/samples/tutorial/05_getting_results/run1.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=15)
            dump_path = tmpdir + "/tasks.bin"
            self.assertTrue(os.path.exists(dump_path))
            # assert results
            tasks = load_binary(dump_path)
            self.assertEqual(tasks[0]["results"], (1.0, 2.0, 3.0))

    def test_05_2(self):
        script = self.caravan_dir + "/samples/tutorial/05_getting_results/run2.sh"
        with tempfile.TemporaryDirectory() as tmpdir:
            subprocess.run([script], check=True, cwd=tmpdir, timeout=15)
            dump_path = tmpdir + "/tasks.bin"
            self.assertTrue(os.path.exists(dump_path))
            # assert results
            tasks = load_binary(dump_path)
            self.assertEqual(len(tasks), 4)
            for i in range(4):
                self.assertEqual(tasks[i]["results"][0], float(i))

