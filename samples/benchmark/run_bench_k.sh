#!/bin/sh
#============ pjsub Options ============
#PJM --rsc-list "node=2304"
#PJM --rsc-list "elapse=00:10:00"
#PJM --rsc-list "rscgrp=large"
#PJM --mpi "proc=18432"
#PJM --stg-transfiles all
#PJM --mpi "use-rankdir"
#PJM --stgin  "rank=* ../../build/a.out %r:./"
#PJM --stgin  "rank=0 ./bench_problem.py %r:./"
#PJM --stgin "rank=0 ../../python_module.tar %r:./"
#PJM --stgout-dir "rank=0 %r:./ %j"
#PJM --stgout "rank=0 %r:./stderr.txt.%r ./%j/"
#PJM --stgout "rank=1 %r:./stderr.txt.%r ./%j/"
#PJM -s

. /work/system/Env_base

# settings to use python
export PATH=/opt/klocal/Python-2.7/bin:${PATH}
export LD_LIBRARY_PATH=/opt/klocal/Python-2.7/lib:/opt/klocal/cblas/lib:${LD_LIBRARY_PATH}

# settings to use x10
ulimit -s 8192
export GC_MARKERS=1
export X10_NTHREADS=1
export X10RT_MPI_THREAD_SERIALIZED=1

tar xf python_module.tar
export PYTHONPATH=python_module:$PYTHONPATH
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}

mpiexec -ofout-proc stdout.txt -oferr-proc stderr.txt ./a.out python -u ./bench_problem.py 184320 0 0.25 4 20.0 8.0

