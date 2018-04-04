#!/bin/bash -e

HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python -u $HERE/bench_problem.py 10 40 0.25 4 2.0 0.5"

source ${HERE}/common.sh

