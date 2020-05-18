#!/bin/bash -e

HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="$HERE/bench_problem.py 5 45 0.25 4 1.0 0.4 table.pickle"
export CARAVAN_TIMEOUT=5

source ${HERE}/common.sh

