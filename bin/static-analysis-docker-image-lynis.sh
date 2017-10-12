#!/bin/bash
#
# Docker image testing
#

tmpdir=tmp
#dockerDir=.
#dockerFile=${dockerDir}/Dockerfile
imageDir=output-images
reportsDir=reports
versionFile=${tmpdir}/version
imageFile=${tmpdir}/imageFile
GIT_URL="${GIT_URL%.git}"

mkdir -p ${tmpdir} ${reportsDir}

###
### lynis
###
printf "=%.s" {1..3}
echo -e "Running lynis...\n"
pushd ${tmpdir}
lynis --auditor Jenkins --cronjob audit dockerfile ../${imageFile}
popd
if [ -f /tmp/lynis-report.dat ]; then
  cp /tmp/lynis-report.dat ${reportsDir}/lynis-image.dat
fi
