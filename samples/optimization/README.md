# How to run

Make a temporary directory, cd to it, and run the script.

```
mkdir -p temp
cd temp
../run_opt.sh
```

If you have an MPI-backend program, set `IS_MPI=1`.

```
env IS_MPI=1 ../run_opt.sh
```

# specification of the program

This is a sample of optimization problem.
It minimizes the output of the evaluation function of a quadratic function using a Differential Evolution algorithm.

Its parameters are as follows:

- `n` : population size
- `f` : differential weight
- `cr` : crossover probability
- `tmax` : number of iterations

After you run the command, you'll see "opt_log.txt" file, which shows the time evolution of the found best solution.

