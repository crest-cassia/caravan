# How to run

This is a sample of multi-objective optimization using NSGA-II algorithm.
The code depends on [deap](https://github.com/DEAP/deap) library.
You also need `numpy` and `matplotlib` to run this sample.

```
pip install deap numpy matplotlib
```

Run the script as follows.

```
./run.sh
```

# What we changed from the original sample

nsga2.py is made from a sample provided by deap library.
Most of the part remain same as the original one. What we changed are the followings.

- defined `evaluate_population(population)` function instead of `map(evaluate, population)` in order to run evaluation in parallel.
    - evaluation of the function is written using caravan APIs
- `map_params_to_cmd` function generates a command to calculate a benchmark function

# LICENSE

`nsga2.py` and `pareto_front` is made based on a sample code of deap library.
These are distributed under the license of deap.
See the license term of [deap](https://github.com/DEAP/deap).

The other files are provided under the MIT license.

