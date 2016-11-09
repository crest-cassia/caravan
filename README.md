# CARAVAN

A framework for large scale parameter-space exploration.

## Prerequisites

- x10 2.5.4 or later
    - tested against native x10 2.5.4 with MPI backend

## Compiling a sample project

To build an executable, you have to combine the framework and your own codes.
The combination of the framework and the user-specific codes is called "project".

You can find sample projects in `samples` directory.

Let us compile a sample project "Minimum".

```
cd samples/Minimum
./build.sh
```

By default, "Socket" is selected as X10RT. If you are going to build an MPI-backed program, set environment variable "IS\_MPI" to "1" when building it.

```
cd samples/Minimum
env IS_MPI=1 ./build.sh
```

The executables are built in the `build/` directory. To run the sample project, cd to `build/` and then run the program.

```
cd build
env X10_NPLACES=8 ./a.out 1234
```

or, for MPI-backed program,

```
cd build
mpiexec -n 8 ./a.out 1234
```

Here the argument is the random number seed.
Specification of the arguments depends on each project.

The environment variable `X10_NPLACES` specifies the number of places (i.e. processes) for socket-backed programs.
The number of places must be larger than 1 because CARAVAN needs at least one job-producer and one job-consumer processes.

After running the command, you'll find `dump.bin` file, where the simulation results are stored.
For the file format of the dump file, see [dump_format.md](dump_format.md).

## Building a benchmark project

In order to test the performance of the framework, we prepared a project for benchmark, which are found in `benchmark` directory.
Thie benchmark test the performance of the task-queue handlnig.

To build the benchmark project,

```
cd benchmark
./build.sh
```

To run the program,

```
env X10_NPLACES=8 ./a.out 10 90 0.25 4 0.5 0.1 30 4
```

If you use MPI, set `IS_MPI=1` when building it and use `mpiexec` when running the program, as in the sample project.
Specification of the arguments are described in the following.

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

- `Main.x10`
    - Main function of the executable
- `build.sh`
    - a script to build your project
- `Simulator.x10`
    - Definition of the simulator. Information specific to your simulator is defined in this class.
- [optional] Simulation code written in C++
    - If you'd like to run a simulator written in C++, you need to prepare the codes.
- [optional] Searcher class
    - This class defines how caravan searches in parameter-space. If you are going to use one of the predefined searchers, please skip this step.

A minimal project is found in `sample/Minimum` directory, which contains `Main.x10`, `build.sh`, and `Simulator.x10`.
Copy this directory and make your own project based on this.


