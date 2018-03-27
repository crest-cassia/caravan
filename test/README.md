## Running tests

Here is the tests to test samples in "samples/" directory.
After building the scheduler, run the following command at the top directory.

```bash
$ python -m unittest discover test
```

To run a specific test case, run a command like the following.

```bash
$ python -m unittest test.test_tutorial_samples.TutorialSamplesTest.test_05_2
```

