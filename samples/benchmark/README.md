# How to run

Make a temporary directory, cd to it, and run the script.

```
mkdir -p temp
cd temp
../run_bench.sh
```

If you have an MPI-backend program, set `IS_MPI=1`.

```
env IS_MPI=1 ../run_bench.sh
```

# specification of the program

## run_bench.sh

This benchmark is designed to test the performance of the job distribution in massive parallel environments.
The simulation program for this benchmark problem is "sleep", so that we can measure the scheduling performance.

This program has the following parameters.

- `numStaticJobs`
- `numDynamicJobs`
- `numJobsPerGen`
- `jobGenProb`
- `sleepMu`
- `sleepSigma`

Initially a given number of jobs, which we call static jobs, are created. The number of initial jobs is `numStaticJobs`.
After each job is finished, `numJobsPerGen` jobs are generated with probability `jobGenProb` until the total number of such dynamically generated jobs becomes `numDynamicJobs`.
Each job sleeps for a duration which is randomly drawn from a uniform distribution [`sleepMu`-`sleepSigma`, `sleepMu`+`sleepSigma`].

## run_bench2.sh

This is another benchmark of the scheduler.

The program has the following parameters:

- num_max_job
- num_min_job
- iteration
- num_jobs_per_gen
- sleep_mu
- sleepsigma

Initially `num_max_job` jobs are generated.
When the number of unfinished runs becomes less than `num_min_job`, `num_jobs_per_gen` jobs are newly added to the queue.
The above process iterates `iteration` times.

Each job sleeps for a duration which is randomly drawn from a uniform distribution [`sleepMu`-`sleepSigma`, `sleepMu`+`sleepSigma`].

## run_bench_abort.sh & run_bench_resume.sh

The specification of `run_bench_abort.sh` is same as `run_bench.sh` but it sets `CARAVAN_TIMEOUT=5`, indicating the whole process is aborted after 5 seconds.
The state is dumped to `tables.msgpack` file.
To restart the process, run `run_bench_resume.sh`. If you run `run_bench_resume.sh` several times, all the jobs will end eventually.

```
../run_bench_abort.sh          # some of the jobs are executed, and then aborted.

../run_bench_resume.sh         # the remaining jobs will be executed.
```

