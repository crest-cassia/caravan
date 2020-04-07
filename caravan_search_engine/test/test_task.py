import unittest
from caravan.task import Task
from caravan.tables import Tables


class TestRun(unittest.TestCase):
    def setUp(self):
        self.t = Tables.get()
        self.t.clear()

    def test_task(self):
        t = Task(1234, "echo hello world")
        self.assertEqual(t.id(), 1234)
        self.assertEqual(t.is_finished(), False)
        self.assertEqual(t.command(), "echo hello world")
        t.store_result([1.0, 2.0, 3.0], 0, 3, 111, 222)
        self.assertTrue(t.is_finished())
        self.assertEqual(t.rc(), 0)
        self.assertEqual(t.rank(), 3)
        self.assertEqual(t.start_at(), 111)
        self.assertEqual(t.finish_at(), 222)

    def test_create(self):
        for i in range(10):
            t = Task.create("echo %d" % i)
            self.assertEqual(t.id(), i)
            self.assertEqual(t.is_finished(), False)
        self.assertEqual(len(Task.all()), 10)

    def test_all(self):
        tasks = [Task.create("echo %d" % i) for i in range(10)]
        self.assertEqual(Task.all(), tasks)

    def test_find(self):
        tasks = [Task.create("echo %d" % i) for i in range(10)]
        self.assertEqual(Task.find(5).id(), 5)
        self.assertEqual(Task.find(5), tasks[5])


if __name__ == '__main__':
    unittest.main()
