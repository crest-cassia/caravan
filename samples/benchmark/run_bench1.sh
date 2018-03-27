#!/bin/bash -ex

HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python -u $HERE/bench_problem.py 10 90 0.25 4 3.0 0.8"

source ${HERE}/common.sh

