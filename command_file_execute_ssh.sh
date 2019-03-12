#!/bin/bash

if [ $# -ne 1 ] ; then
  echo "Usage: $0 commandlines"
  exit 1
fi

if [ -z "${SLURM_JOBID}" ] ; then
  echo "Script $0 can only be run inside a batch or idev run"
  exit 1
fi

##
## make a hostfile for this gnuparallel run
##
if [ ! -d ${HOME}/.slrum ] ; then
  mkdir -p ${HOME}/.slrum
fi
NODEFILE=${HOME}/.slrum/gnuparallel_hostfile
rm -f ${NODEFILE}
if [ ${TACC_GNUPARALLEL_LIMIT:=0} -eq 0 ] ; then
      limit_per_node=$(( SLURM_NPROCS / SLURM_NNODES ))
else
      limit_per_node=${TACC_GNUPARALLEL_LIMIT}
fi
for h in `scontrol show hostname ${SLURM_NODELIST}` ; do
      echo ${limit_per_node}//bin/ssh `whoami`@$h >> ${NODEFILE}
done
#echo "nodefile:" ; cat ${NODEFILE}

##
## now do an ssh parallel run
##
ncommands=`cat $1 | wc -l`
parallel --sshloginfile ${NODEFILE} --sshdelay 0.2 \
    gnuparallel_command_execute.sh "$1" ::: `seq 1 $ncommands`
