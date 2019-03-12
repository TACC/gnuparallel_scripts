#!/bin/bash

usage () {
  echo "Usage: $0 [ -l limit ] [ -vV ] commandlines"
  exit 1
}

if [ $# -eq 0 ] ; then usage ; fi

if [ -z "${SLURM_JOBID}" ] ; then
  echo "Script $0 can only be run inside a batch or idev run"
  exit 1
fi
if [ -z "${TACC_GNUPARALLEL_DIR}" ] ; then
  echo "Please load module gnuparallel"
  exit 1
fi

####
#### Parameter parsing
####
verbose=0
while [ $# -gt 0 ] ; do
  if [ "$1" = "-h" ] ; then 
    usage ; exit 0 ;
  elif [ "$1" = "-v" ] ; then 
    verbose=1 ; shift
  elif [ "$1" = "-V" ] ; then 
    verbose=1 ; set -x ; shift
  elif [ "$1" = "-l" ] ; then
    shift
    if [ $# -lt 2 ] ; then usage ; fi
    TACC_GNUPARALLEL_LIMIT="$1" ; shift
  elif [ $# -eq 1 ] ; then
    COMMANDFILE=$1 ; shift
  fi
done
if [ -z "${COMMANDFILE}" ] ; then 
  usage ; exit 1
fi

ENVCOMMANDFILE=/tmp/"${COMMANDFILE}"
cat "${COMMANDFILE}" \
| sed -e "s?^?env `/opt/apps/launcher/launcher-3.2/pass_env` ?" \
> "${ENVCOMMANDFILE}"

####
#### make a hostfile for this gnuparallel run
####
if [ ! -d ${HOME}/.slurm ] ; then
  mkdir -p ${HOME}/.slurm
fi
NODEFILE=${HOME}/.slurm/gnuparallel_hostfile
rm -f ${NODEFILE}
if [ ${TACC_GNUPARALLEL_LIMIT:=0} -eq 0 ] ; then
      limit_per_node=$(( SLURM_NPROCS / SLURM_NNODES ))
else
      limit_per_node=${TACC_GNUPARALLEL_LIMIT}
fi
if [ $verbose -gt 0 ] ; then
  echo "Simultaneous task limit: ${limit_per_node}"
fi
for h in `scontrol show hostname ${SLURM_NODELIST}` ; do
      echo ${limit_per_node}//bin/ssh `whoami`@$h >> ${NODEFILE}
done
if [ $verbose -gt 0 ] ; then
  echo "nodefile:" ; cat ${NODEFILE}
fi

##
## now do an ssh parallel run
##
ncommands=`cat ${COMMANDFILE} | wc -l`
COMMANDDIR=`pwd`
parallel --sshloginfile ${NODEFILE} --sshdelay 0.2 --workdir ${COMMANDDIR} \
    ${TACC_GNUPARALLEL_SRC}/scripts/gnuparallel_command_execute.sh \
        "${ENVCOMMANDFILE}" \
    ::: `seq 1 $ncommands`
