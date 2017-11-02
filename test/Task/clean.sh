#!/bin/bash -ux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}

rm -f stdout
rm -f stderr
rm -rf w00000132
rm -rf w00001043

