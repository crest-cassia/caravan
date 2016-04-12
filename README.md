
# CARAVAN

A framework for large scale parameter-space exploration.

## Prerequisites

- x10 2.5.0 or later
    - tested against native x10 2.5.0 with MPI backend

## Compiling a sample project

To build an executable, you have to combine the framework and your own codes.
The combination of the framework and the user-specific codes is called "project".

You can find samples of projects in `samples` directory.

Let us compile a sample project "dummy". Run the following script in the top directory

```
./samples/dummy/build.sh
```

The executables are built in the `build/` directory. To run the sample project, cd to `build/` and then run

```
X10_NPLACES=8 ./a.out 100 0.1 0.01 5 4
```

The variable `X10_NPLACES` specifies the number of places (i.e. processes).
The number of places must be larger than 1 to run caravan appropriately.

The results are stored in `runs.json` and `parameter_sets.json` files.

## Preparing your own project

To appear...

