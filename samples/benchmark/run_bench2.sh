#!/bin/bash -e

HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python -u $HERE/bench_problem2.py 50 0 5 20 1.0 0.8"

source ${HERE}/common.sh

