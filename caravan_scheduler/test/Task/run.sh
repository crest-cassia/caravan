#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}

${BUILD}/a.out > stdout
diff stdout expected_stdout && echo OK

