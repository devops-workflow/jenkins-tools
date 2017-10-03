#!/bin/bash
#
# Dockerfile testing
#
#  whale-linter

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
### whale-linter
###
printf "=%.s" {1..3}
echo -e "Running whale-linter...\n"
docker run -i --rm jeromepin/whale-linter --version
docker run -i --rm -v ${WORKSPACE}/${dockerFile}:/Dockerfile jeromepin/whale-linter | tee ${reportsDir}/whale-linter.output

#chmod +x ${tmpdir}/parse-whale-linter.sh
parse-whale-linter.sh ${reportsDir}/whale-linter.output > ${reportsDir}/whale-linter.warnings
