# How to run

```
./run_opt.sh
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

