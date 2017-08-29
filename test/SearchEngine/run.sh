#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}

${BUILD}/a.out > tested.txt
diff tested.txt expected.txt && echo OK && rm tested.txt

