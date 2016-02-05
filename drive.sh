#!/usr/bin/env bash
set -x

if [[ $# -lt 4 ]]; then
  echo "Usage: drive.sh <target_os> <arch> <compiler> <other_host>"
  echo "    target_os -- 'bitrig', 'netbsd', etc"
  echo "    arch      -- 'x86_64', 'i686', 'armv7', etc"
  echo "    compiler  -- 'gcc' or 'clang'"
  echo "    other_host -- the fqdn of the other host to work with"
  exit 1
fi

set -x
HOST=`uname -s | tr '[:upper:]' '[:lower:]'`
TARGET=$1
ARCH=$2
COMP=$3
OTHERMACHINE=$4

wait_for_file(){
  while [ ! -e ${1} ]; do
    sleep 60
  done
  echo "${1} received from ${OTHERMACHINE}..."
}

setup(){
  rm -rf stage1 stage2 stage3 stage4 stage1.tgz stage2.tgz stage3.tgz
  TOP=`pwd`
}

do_host() {
  echo "Driving the host side..."
  cd ${TOP}
  ./stage1.sh ${TARGET} ${ARCH} ${COMP} 2>&1 | tee build1.log
  if (( $? )); then
    echo "stage1 ${HOST} failed"
    exit 1
  fi
  cd ${TOP}
  wait_for_file stage1.tgz
  tar -zxvf stage1.tgz
  ./stage2.sh ${TARGET} ${ARCH} ${COMP} 2>&1 | tee build2.log
  if (( $? )); then
    echo "stage2 ${HOST} failed"
    exit 1
  fi
  cd ${TOP}
  scp stage2.tgz ${OTHERMACHINE}:/opt/rust-cross-tookit/
}

do_target(){
  echo "Driving the target side..."
  cd ${TOP}
  ./stage1.sh ${TARGET} ${ARCH} ${COMP} 2>&1 | tee build1.log
  if (( $? )); then
    echo "stage1 ${HOST} failed"
    exit 1
  fi
  cd ${TOP}
  scp stage1.tgz ${OTHERMACHINE}:/opt/rust-cross-bitrig/
  wait_for_file stage2.tgz
  tar -zxvf stage2.tgz
  ./stage3.sh ${TARGET} ${ARCH} ${COMP} 2>&1 | tee build3.log
  if (( $? )); then
    echo "stage3 ${HOST} failed"
    exit 1
  fi
  cd ${TOP}
  ./stage4.sh ${TARGET} ${ARCH} ${COMP} 2>&1 | tee build4.log
  if (( $? )); then
    echo "stage4 ${HOST} failed"
    exit 1
  fi
}

setup
if [ ${HOST} == ${TARGET} ]; then
  do_target
else
  do_host
fi
