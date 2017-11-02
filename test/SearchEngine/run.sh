#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}

${BUILD}/a.out 2> stderr > stdout
diff stdout expected_stdout && diff stderr expected_stderr && echo OK

