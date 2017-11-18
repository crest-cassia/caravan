# CARAVAN

A framework for large scale parameter-space exploration.

## Prerequisites

- x10 2.5.4 or later
    - tested against native x10 2.5.4 with MPI backend
- Python 2.7 or later        

## Compiling a sample project

```
./build.sh
```

By default, "Socket" is selected as X10RT. If you are going to build an MPI-backed program, set environment variable "IS\_MPI" to "1" when building it.

```
env IS_MPI=1 ./build.sh
```

The executables are built in the `build/` directory. To run the sample project, cd to `build/` and then run the program.

```
cd build
env X10_NPLACES=8 ./a.out python -u ../sample/benchmark/bench.py 20 0 0.0 0 2.0 1.5 
```

or, for MPI-backed program,

```
cd build
mpiexec -n 8 ./a.out python -u ../sample/benchmark/bench.py 20 0 0.0 0 2.0 1.5 
```

The environment variable `X10_NPLACES` specifies the number of places (i.e. processes) for socket-backed programs.
The number of places must be larger than or equal to 3 because CARAVAN uses at least 3 process for task scheduling.

After running the command, you'll find `tasks.bin` file, where the simulation results are stored.
For the file format of the dump file, see [dump_format.md](dump_format.md).

### Specification of the benchmark

This benchmark is designed to test the performance of the job distribution in massive parallel environments.
The simulation program is "sleep", which eliminates the performance of the job execution.

This program has the following parameters.

- `numStaticJobs`
- `numDynamicJobs`
- `numJobsPerGen`
- `jobGenProb`
- `sleepMu`
- `sleepSigma`
- `timeOut`
- `numProcPerBuf`

Initially a given number of jobs, which we call static jobs, are created. The number of initial jobs is `numStaticJobs`.
After each job is finished, `numJobsPerGen` jobs are generated with probability `jobGenProb` until the total number of such dynamically generated jobs are less than `numDynamicJobs`.
Each job sleeps for a duration which is randomly drawn from a uniform distribution [`sleepMu`-`sleepSigma`, `sleepMu`+`sleepSigma`].

The `timeOut` limits the elapsed time of the program.

`numProcPerBuf` is a parameter for the job distribution. It specifies the number of consumer-processes for each buffer process.

## Preparing your own project

To make your own project, you need to prepare the things listed in the following.

- `main.py`
    - Main python function of the searcher


