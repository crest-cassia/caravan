# How to run

Make a temporary directory, cd to it, and run the script.

```
mkdir -p temp
cd temp
../run.sh
```

If you have an MPI-backend program, set `IS_MPI=1`.

```
env IS_MPI=1 ../run.sh
```

# specification of the program

This program reads the list of commands from `commands` file. Then it executes these commands in parallel.

