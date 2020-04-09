# CARAVAN

A framework for large scale parameter-space exploration.
Using CARAVAN, you can easily run your simulation programs or other computational jobs with a bunch of different parameters in parallel using HPCs.
Possible applications include

- embarrassingly parallel problem
- parameter tuning
- data assimilation
- optimization of parameters
- sensitivity analysis

## How it works

The following figure illustrates the whole architecture of CARAVAN.

<p align="center"><img src="figs/caravan_overview.png" alt="caravan_overview" width="640"></p>

CARAVAN consists of three parts: **search engine**, **scheduler**, and **simulator**.

**Simulator** is an executable program which you want to execute in parallel. Since it is executed as an external process, it must be prepared as an executable program beforehand, i.e., it must be compiled in advance. You can implement a simulator in any language.

**Scheduler** is a part which is responsible for parallelization. It receives the commands to execute simulators from **search engine**, distributes them to available nodes, and executes the **simulator** in parallel. This part is implemented in C++ using MPI, and users are not supposed to edit it by themselves. If a system administrator provides a binary executable, users do not even have to compile it.

**Search engine** is a part which determines the policy on how parameter-space is explored. More specifically, it generates a series of commands to be executed in parallel, send them to **scheduler**. It also receives the results from the scheduler when these tasks are done. Based on the received results, **search engine** can generate other sets of tasks repeatedly as many as you want.

Prepare a simulator and a search engine to conduct parameter-space exploration. Once these are implemented, it can scale up to tens of thousands of processes.

### Expected scale of tasks

CARAVAN is designed for cases where the duration of each task (a single run of your simulator) typically ranges from several seconds to several hours.
CARAVAN does not perform quite well for tasks which finish in less than a few seconds. One of the reasons for this limitation comes from the design decision that a simulator is executed as an external process. For each task, CARAVAN makes a temporary directory, creates a process, and reads a file generated by the simulator, which amounts to some overheads.
If you would like to run such fine-grained tasks, consider using other frameworks such as Map-Reduce or Spark.
Instead, the scheduler of CARAVAN is designed such that it achieves ideal load balancing even when the durations vary significantly. The tolerance for the variation in time is essential for parameter-space exploration since elapsed times usually depends remarkably on the parameter values.
CARAVAN is designed so as to scale up well to tens of thousands of MPI processes for tasks of this scale.

Another difference from Map-Reduce like frameworks is that it is possible to define callback functions which are invoked when each task is finished. This is necessary for various parameter-space exploration including optimization and Markov chain Monte Carlo parameter-space sampling. With these callbacks, we can determine the parameter-space to explore based on the existing simulation results.

Another limitation of CARAVAN is that a simulator must be a serial program or multi-thread program. It must not be an MPI-parallel program. This is because CARAVAN launches the command as an external process, not as an MPI process invoked by `MPI_Comm_Spawn` function. In such cases, you may use another framework such as `concurrent.futures` module of mpi4py. If you have a serial or OpenMP program, on the other hand, it is easy to integrate your simulator into CARAVAN.

## Installation

### Prerequisites

- (for scheduler) C++17 with MPI
- (for search engine) msgpack-python
    - `pip install msgpack-python`
- (for search engine) python-fibers (optional)
    - `pip install fibers`
    - This module supports x86, x86-64, ARM, MIPS64, PPC64 and s390x. Although you may skip the installation of this module, installation is recommended for a program using async-await pattern extensively.

### Building the scheduler

First of all, clone the source code. As it contains git submodules, do not forget `--recursive` option.

```console
$ git clone --recursive https://github.com/crest-cassia/caravan
```

Then, run the following shell script to build the scheduler.

```console
$ cd caravan_scheduler
$ mpicxx -o scheduler -O3 main.cpp
```

### Running a sample project

To run a sample code, make a temporary directory and run the shell script in the sample directory.

```console
$ mkdir -p temp
$ cd temp
$ {CARAVAN_DIR}/samples/benchmark/run_bench1.sh
```

The shell script is written like the following.
The number of MPI processes must be larger than or equal to 3 because CARAVAN uses at least 3 processes for task scheduling.

After running the command, you'll find `tasks.msgpack` file, which contains information of task scheduling.
You can visualize it using [caravan_viz](https://github.com/crest-cassia/caravan_viz).

## Samples

Several samples are in `samples/` directory, which include

- [file_input](samples/file_input): An example of embarrassingly parallel problem. Executes commands listed in a file in parallel.
- [optimization](samples/optimization): A simple optimization problem using a differential evolution algorithm
- [multi-objective optimization](samples/nsga2): A multi-objective optimization problem using a python library

See the README in each directory for the usage.

## Preparation of your simulator

A simulator may be any executable program. However, simulators that satisfying the following conditions are easy to integrate.

1. generate outputs in the current directory
1. accept parameters for simulations from `_input.json` file
1. write results to `_output.json` file

Prepare a simulator such that it reads its parameters from json file `_input.json`.
This is because a Task is created by specifying a command line string (e.g. `~/path/to/your_simulator`) and an associative array (a dictionary in Python) such as `{"param1":0.5, "param2":1.5}`.
To conform to the input format given by CARAVAN, you might want to use a shell script (or other kinds of scripts) as your simulator to convert the format of input parameters.

A simulator is supposed to generate its output files in the current directory.
The scheduler makes a directory, called **work directory** hereafter, for each task and executes the simulator after it changed the current directory to this directory.
The path of the work directory is made as `sprintf("w%04d/w%07d", task_id/1000, task_id)`, where **task_id** is a unique integer number given to each simulation task from the search engine.
If the ID of a task is "12345", for instance, the temporary directory for this task is "w0012/w0012345".

If your simulator writes a file `_output.json`, it is parsed by the scheduler and is sent back to the search engine.
This is useful when your search engine determines the next parameters according to the simulation results.
For instance, if you would like to optimize a certain value of the simulation results, write a value which you want to minimize (or maximize) to `_output.json` file.

The work directories remains even after the whole CARAVAN process finished. If necessary, you may further investigate these files later by yourself in order to get more information.

## Preparation of a search engine: A step-by-step tutorial

These samples are in `samples/tutorial` directory. See this directory for the complete samples.

### A minimal code

Search engine is responsible for generating the command to be executed by the scheduler.

A simple "hello world" program of the search engine is as follows.

```hello_caravan.py
from caravan import Server,Task

with Server.start():
    for i in range(10):
        Task.create("echo %d > out" % i)
```

This sample creates a list of tasks, each of which runs "echo {task_id}".
Let us run this search engine with the scheduler.
To execute the program, you need to set `PYTHONPATH` to import `caravan` package. Then, `mpiexec` the scheduler giving the command to execute search engine.

```console
$ CARAVAN_DIR=$(pwd)
$ export PYTHONPATH=$(pwd)/caravan_search_engine:$PYTHONPATH
$ mpiexec -n 8 caravan_scheduler/scheduler python hello_caravan.py
```

You'll see the outputs of the commands executed in parallel in the console.

You also see that the work directories are created under the current directory as shown in the following. Each task is executed in each work directory.
You'll see files named "out" is created in each work directory. Verify that the task IDs are written to the "out" files in each work directory.

Since two-level directories are created as work directories, we need to take care of the simulator path when we specify the command by a relative path. For instance, your simulator is located at the directory where CARAVAN is launched, the path of the simulator must be specified as the "parent of parent" of the current directory like `../../simulator.out`.
A good practice to avoid this complexity is to specify the command by the absolute path, such as `$HOME/simulator.out`.

In the following samples, `import` statements are omitted unless explicitly stated. You can find an executable scripts in `samples/` directory.

### Visualizing how tasks are executed in parallel

Let us visualize the timeseries of task execution and see how tasks are executed in parallel.
We generate 10 tasks which sleeps 1~3 seconds as follows.

```hello_sleep.py
from caravan import Server,Task

with Server.start():
    for i in range(20):
        Task.create(f"sleep {1+i%3}")
```

After the execution, you'll find a binary file "tasks.msgpack". This file is generated by the scheduler.
It has the logs of each tasks such as the executed time, duration, and the process number.
Refer to the [README of CARAVAN_viz](caravan_viz/README), which is a tool to visualize the logs.
With this tool, you'll intuitively see how tasks are executed concurrently.

### Defining callback functions

In many applications such as optimization, new tasks must be generated based on the results of finished tasks. It is possible to define callback functions for that purpose.

```hello_callback.py
from caravan import Server,Task

with Server.start():
    for i in range(6):
        task = Task.create(f"sleep {1+i%3}")
        task.add_callback(lambda i=i: Task.create(f"sleep {1+i%3}"))
```

Run this program with the scheduler and visualize it using caravan_viz.
You'll find that 10 tasks are created and 10 tasks are created after each of the initial tasks finished.

Please note that `i=i` in the last line is an idiom of Python to bind the variable `i` to the value when lambda is defined.
If you refer to `i` directly from inside of the lambda, all the lambda refers to the same value of `i`, which is 5 in this case.

### Async/Await

Although callbacks work fine, the code easily become too complicated if you add nested callbacks.
One of the best practices to avoid the "callback hell" is "async/await" pattern. Let us see an example.

```hello_await.py
from caravan import Server,Task

with Server.start():
    for i in range(5):
        task = Task.create(f"sleep {1+i%3}")
        Server.await_task(task)  # this method blocks until the task is finished.
        print(f"step {i} finished. rc: {task.rc()}, rank: {task.rank()}, {task.start_at()}-{task.finish_at()}") # show info of completed task
```

This program executes 5 tasks sequentially. A new task is created after the previous task completed.

Next, let us run three set of the above sequential tasks in parallel. To define asynchronous function, use `Server.async` method.
If you visualize the results of the following program, you will see three concurrent lines of sequential tasks of length five.

```hello_async_await.py
import functools
from caravan import Server,Task

def run_sequential_tasks(n):
    for i in range(4):
        task = Task.create(f"sleep {1+i%3}")
        Server.await_task(task)  # this method blocks until the task is complete.
        print(f"step {i} of {n} finished")  # show the progress

with Server.start():
    for n in range(3):
        Server.do_async( functools.partial(run_sequential_tasks,n) )
```

Finally, we show how to use `Server.await_all_tasks` function, which waits until all of the given set of tasks finished.

```hello_await_all.py
from caravan import Server,Task

with Server.start():
    tasks1 = [Task.create(f"sleep {1+i%3}") for i in range(5)]
    Server.await_all_tasks(tasks1)  # this method blocks until all the tasks are finished
    print("all running tasks are complete!")
    for t in tasks1:
        print(f"task ID:{t.id()}, rc:{t.rc()}, rank:{t.rank()}, {t.start_at()}-{t.finish_at()}")
```

### Getting the results of simulators

If a simulator writes "_results.txt" file, its contents is parsed by the scheduler and is passed to the search engine.
The results are obtained as lists of float values. The length of the results for each task may vary.

```hello_output.py
from caravan import Server,Task

with Server.start():
    t = Task.create("echo '[1.0,2.0,3.0]' > _output.json")
    Server.await_task(t)
    print(t.output())
```

Note that you have to await task to obtain the results. Otherwise, you'll get `None`.

Here is another sample, which creates tasks depending on the results of finished tasks.

```hello_output_repeat.py
from caravan import Server,Task

with Server.start():
    i = 0
    t = Task.create(f"echo {i} > _output.json")
    while True:
        print(f"awaiting Task({i})")
        Server.await_task(t)
        if t.output() < 3:
            i += 1
            t = Task.create(f"echo {i} > _output.json")
        else:
            break
```

### ParameterSet and Run

Suppose that we have a simulator for a Monte Carlo simulation. In that case, each MC run corresponds to a task.
To simplify the integration of MC simulators to CARAVAN, `ParameterSet` and `Run` classes are prepared.
`ParameterSet` (PS) class corresponds to a set of parameters for the simulator while `Run` corresponds to a MC run. Thus, each PS may have multiple Runs.
Run is a sub-class of Task class.

Here is an example. This sample simulator takes two parameters and one random-number seed. It prints one output values to "_results.txt" file.

```mc_simulator.py
import sys,random

mu = float(sys.argv[1])
sigma = float(sys.argv[2])
random.seed(int(sys.argv[3]))
print(random.normalvariate(mu, sigma))
```

To run this simulator, use the following search engine.

```hello_ps.py
import sys
from caravan.server import Server
from caravan.parameter_set import ParameterSet

# define a function which receives a tuple of parameters and a random-number seed, and returns the command to be executed
def make_cmd( params, seed ):
    args = " ".join( [str(x) for x in params] )
    return "python ../../mc_simulator.py %s %d > _results.txt" % (args, seed)

ParameterSet.set_command_func(make_cmd)             # set `make_cmd`. When runs are created, `make_cmd` is called when Runs are created.

with Server.start():
    ps = ParameterSet.find_or_create(1.0, 2.0)      # create a ParameterSet whose parameters are (1.0,2.0).
    ps.create_runs_upto(10)                         # create ten Runs. In the background, `make_cmd` is called to generate actual commands.
    Server.await_ps(ps)                             # wait until all the Runs of this ParameterSet finishes
    x = ps.average_results()                        # results are averaged over the Runs
    print("average: %f" % x, file=sys.stderr, flush=True)
    for r in ps.runs():
        print(r.results, file=sys.stderr, flush=True)           # showing results of each Run
```

This sample creates one PS and 10 Runs. The results of Runs as well as their average are shown.

The following are the method of `ParameterSet` and `Runs`.

- `ParameterSet` class
    - `.find_or_create(params)`
        - Creates a new PS of the parameters `parmas`. `params` is a tuple of parameter values. If a PS having the same parameters already exists, the existing PS is returned instead of making a new one.
    - `#create_runs_upto(num_runs)`
        - Runs are created under the PS. Runs are repeatedly created until the number of runs becomes `num_runs`.
    - `#average_results()`
        - returns results averaged over the Runs. Element-wise averaging is conducted assuming the length of the results are same.
    - `#runs()`
        - returns list of its Runs.
    - `#finished_runs()`
        - returns list of its Runs that are finished.
    - `#is_finished()`
        - returns True if all of its Runs are finished.
    - `#params`
        - a tuple of the parameters.
- `Run` class
    - `#parameter_set()`
        - returns its ParameterSet object.
    - `#seed`
        - its random number seed.

Here, we show another example that incrementally increases the number of Runs when the sample average does not converge enough. (The first half of the code is omitted since it is same as the previous one.)

```hello_ps_convergence.py
def eprint(str):
    print(str, file=sys.stderr, flush=True)

def converged(ps):
    runs = ps.runs()
    r1 = [r.results for r in runs]
    errs = np.std(r1, axis=0, ddof=1) / math.sqrt(len(runs))
    eprint(errs)
    return np.all(errs < 0.2)


with Server.start():
    ps = ParameterSet.find_or_create(1.0, 2.0)
    ps.create_runs_upto(4)
    eprint("awaiting")
    Server.await_ps(ps)
    while not converged(ps):
        ps.create_runs_upto(len(ps.runs()) + 4)  # add four runs
        eprint("awaiting")
        Server.await_ps(ps)
    print(ps.average_results(), file=sys.stderr)
```

It is also possible to do the same thing for other parameters concurrently using `Server.async` method.


```hello_ps_convergence_concurrent.py
def do_until_convergence(params):
    ps = ParameterSet.find_or_create(params)
    ps.create_runs_upto(4)
    Server.await_ps(ps)
    while not converged(ps):
        eprint("results for {params} is not converged".format(**locals()))
        ps.create_runs_upto(len(ps.runs())+4)     # add four runs
        Server.await_ps(ps)
    eprint("converged results : {0}, params {1}".format(ps.average_results(), params))


with Server.start():
    for p1 in [1.0, 1.5, 2.0, 2.5]:
        for p2 in [2.0, 3.0]:
            Server.async(lambda _param=(p1, p2): do_until_convergence(_param))
```

### Testing your search engine using ServerStub

When you implement a search engine, you should test your algorithm before you run it with your simulator. `ServerStub` class lets you run your search engine with a dummy simulator instead of actually running your simulator.
By defining a function which returns an expected results and elapsed time, you can verify that your search engine works as expected.

First define a function that receives a task instance and returns a tuple of expected results and elapsed time.

```py
def stub_sim(task):
    results = (task.id + 3, task.id + 10)
    elapsed = 1
    return results, elapsed
```

Then, replace `Server.start()` with `start_stub(stub_sim)` as follows.

```diff
+import caravan.server_stub import start_stub

-with Server.start():
+with start_stub(stub_sim, num_proc=4):
```

Run this search engine as a stand-alone python program.

```sh
$ python my_search_engine.py
```

Then, your search engine is executed for a pre-defined dummy simulator without invoking actual tasks.
A file "tasks.bin" is created, with which you may visualize the task scheduling.

The `start_stub` method also works for Runs. After you implemented a search engine, modify your code as follows, which lets you test your code.

```diff
+from caravan.server_stub import start_stub
+import random
+
+def stub_sim(run):                                 # define a stub code that returns expected results and elapsed time
+    params = run.parameter_set().params
+    results = (random.normalvariate(params[0], params[1]),)
+    return results, 1.0
+
-with Server.start():
+with start_stub(stub_sim):
```

### Serializing Tasks, ParameterSets, and Runs

When each job takes long durations, you probably want to serialize your status of Tasks, Runs and ParameterSets before finishing the whole process.
To serialize these, call `Table.dump( filename )`.
The following is a small example.

```py
import sys
from caravan.server import Server
from caravan.task import Task
from caravan.tables import Tables

def eprint(s):
    print(s, file=sys.stderr, flush=True)

with Server.start():
    for i in range(10):
        t = Task.create("sleep %d; echo %d > out" % (i%3,i))
        eprint("task %i is created." % i)
Tables.dump('my_dump')                # dump the results to a file
```

The dumped data can be loaded in another program. For instance, open Python REPL and run the following.

```py
from caravan.tables import Tables
from caravan.task import Task
Tables.load("my_dump")         # data are loaded
for t in Task.all():
    print(t.to_dict())         # print Tasks
```

## How to run tests

Unit tests are in `tests` directory. Run the unit tests by the following command.

```
env CARAVAN_LOG_LEVEL=1 python -m unittest discover test
```

## License

See [LICENSE](LICENSE).

