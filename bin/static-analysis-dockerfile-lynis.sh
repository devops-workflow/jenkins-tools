#!/bin/bash
#
# Dockerfile testing
#
#  lynis

tmpdir=tmp
dockerDir=.
reportsDir=reports
if [ -n "${dockerfilePath}" ]; then
  # Support passing in Dockerfile path by env variable
  dockerFile=${dockerfilePath}
else
  dockerFile=${dockerDir}/Dockerfile
fi

mkdir -p ${tmpdir}
mkdir -p ${reportsDir}

###
### lynis
###
printf "=%.s" {1..3}
echo -e "Running lynis...\n"
# TODO: verify why changing dir. Casues issue with Dockerfile location
pushd ${tmpdir}
lynis --auditor Jenkins --cronjob audit dockerfile ../${dockerFile}
popd
if [ -f /tmp/lynis-report.dat ]; then
  cp /tmp/lynis-report.dat ${reportsDir}/lynis-dockerfile.dat
fi
