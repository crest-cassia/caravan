#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}
mkdir -p ${BUILD}
BUILD=$(cd $BUILD && pwd) # get absolute path

x10c++ -sourcepath ${SCRIPTDIR}/../.. -d ${BUILD} ${SCRIPTDIR}/TaskTest.x10 -VERBOSE_CHECKS

