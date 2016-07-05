# Sensitivity Analysis

A sample of global sensitivity analysis using [SAlib](https://github.com/salib/salib).
To conduct sensitivity analysis, a python library is used to generate parameter sets.
Using this library, the sample points are written to a file. Caravan reads this file and generate runs, then distributes them to available processors.
After these runs are finished, the simulation results are analyzed by SAlib.

## Prerequisites

Prepare python salib module.
If you are using Mac, you can prepare the environment as follows for example.

```
brew update
brew upgrade pyenv
pyenv install miniconda3-3.19.0
pyenv local miniconda3-3.19.0
conda create --name salib numpy scipy matplotlib
source ~/.pyenv/versions/miniconda3-3.19.0/envs/salib/bin/activate salib
conda install pip
pip install salib
```

Once you created an environment, you can load it like

```
source ~/.pyenv/versions/miniconda3-3.19.0/envs/salib/bin/activate salib
```

## Generating sample points using SAlib

If your simulator has three input parameters, we first need to prepare "param.txt" file as follows.
In this sample, param.txt is already prepared.
If you would like to try with your simulator, prepare "param.txt" by yourself.
When you prepare the file, specify [0,1] for the ranges of all the parameters. The domain is calculated by the framework.

```txt:param.txt
x1 0.0 1.0
x2 0.0 1.0
x3 0.0 1.0
```

Then run SAlib to generate sample points as follows:

```
python -m SALib.sample.saltelli -n 1000 -p ./param.txt -o model_input.txt --delimiter=' ' --max-order=1
```

The number of generated points is $n(d+2)$, where "n" is the number you specify as the command-line argument and "d" is the number of input parameters.
In this case, you'll find 5000 points in "model_input.txt" since number of inputs is three.

## Building

Based on the generated sampling points, CARAVAN distributes the runs to available processors.
To build this sample, run `./build.sh`. Then the executables are generated in `build/` directory.
In this example, the simulation code is a simple function for which sensitivity indices are analytically obtained.

## Running

After you copied "model_input.txt" to the current directory, run the command as follows:

```
X10_NPLACES=8 ./build/a.out model_input.txt
```

## Analyzing

After you run the simulations, you will find "ps_ids.txt" in addition to "dump.bin".
"ps_ids.txt" has the list of PS IDs for each sample point. Since an identical PS can be generated, we need to map the input sample points to the PS IDs using this file.

To analyze the results, run the following command:

```
python analyze.py param.txt ps_ids.txt runs.json
```

The results are shown in the stdout like

```
Parameter S1 S1_conf ST ST_conf
x1 0.306432 0.093378 0.560137 0.092284
x2 0.447766 0.067390 0.438727 0.040570
x3 -0.001065 0.072936 0.242842 0.027370
```

indicating the "x2" has the highest first-order sensitivity index while that for "x3" is negligible.
The total sensitivity indices, shown in the last two columns, indicate the sensitivity including all the interactions between input parameters.

