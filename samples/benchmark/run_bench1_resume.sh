#!/bin/bash -e

HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python $HERE/bench_problem.py 10 90 0.25 4 3.0 0.8 table.pickle"
export CARAVAN_TIMEOUT=15

source ${HERE}/common.sh

