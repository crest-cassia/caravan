#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}
mkdir -p ${BUILD}
BUILD=$(cd $BUILD && pwd) # get absolute path
IS_MPI=${IS_MPI:-0}

if [ $IS_MPI = 1 ]; then
  x10c++ -v -O -x10rt mpi -sourcepath ${SCRIPTDIR}/..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/Main.x10 -VERBOSE_CHECKS
else
  x10c++ -v -O            -sourcepath ${SCRIPTDIR}/..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/Main.x10 -VERBOSE_CHECKS
fi

