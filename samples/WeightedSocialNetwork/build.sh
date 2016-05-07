#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}
mkdir -p ${BUILD}
BUILD=$(cd $BUILD && pwd) # get absolute path
IS_MPI=${IS_MPI:-0}

cd ${SCRIPTDIR}/simulator
make
cp libwsn.a ${BUILD}
cd -

if [ $IS_MPI = 1 ]; then
  x10c++ -v -O -x10rt mpi -sourcepath ${SCRIPTDIR}/../..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/WSNSearch.x10 -VERBOSE_CHECKS -post '# # libwsn.a -fopenmp'
else
  x10c++ -v -O            -sourcepath ${SCRIPTDIR}/../..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/WSNSearch.x10 -VERBOSE_CHECKS -post '# # libwsn.a -fopenmp'
fi
