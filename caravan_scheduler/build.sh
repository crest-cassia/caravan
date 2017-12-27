#!/bin/bash -eux

X10CPP=${X10CPP:-x10c++}
SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}
mkdir -p ${BUILD}
BUILD=$(cd $BUILD && pwd) # get absolute path
IS_MPI=${IS_MPI:-0}

cd ${SCRIPTDIR}
if [ $IS_MPI = 1 ]; then
  ${X10CPP} -v -report postcompile=1 -O -x10rt mpi -d ${BUILD} ${SCRIPTDIR}/caravan/Main.x10 -VERBOSE_CHECKS
else
  ${X10CPP} -v -report postcompile=1 -O            -d ${BUILD} ${SCRIPTDIR}/caravan/Main.x10 -VERBOSE_CHECKS
fi

