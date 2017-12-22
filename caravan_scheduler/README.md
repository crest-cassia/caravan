# CARAVAN Scheduler

The scheduler part of CARAVAN framework.

## Building the scheduler

You need an X10 compiler as a prerequisite. Run the following scripts.

```
./build.sh
```

By default, "Socket" is selected as X10RT. If you are going to build an MPI-backed program, set environment variable "IS\_MPI" to "1" when building it.

```
env IS_MPI=1 ./build.sh
```

The executables are built in the `build/` directory.

## Running tests

Run `test/build.sh` and executes it.

```
cd test
./build.sh
./build/a.out
```

## License

MIT License

Copyright (c) 2017 RIKEN AICS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

