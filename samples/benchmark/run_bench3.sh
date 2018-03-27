#!/bin/bash -ex

HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python -u $HERE/bench_problem3.py 300 2 0.1 20.0"

source ${HERE}/common.sh

