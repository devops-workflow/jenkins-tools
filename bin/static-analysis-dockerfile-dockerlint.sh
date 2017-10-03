#!/bin/bash
#
# Dockerfile testing
#
#  dockerlint              https://github.com/redcoolbeans/dockerlint

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
### dockerlint
###
printf "=%.s" {1..3}
echo -e "Running dockerlint...\n"
docker run -i --rm redcoolbeans/dockerlint -h | head -n 1
docker run -i --rm -v "${WORKSPACE}/${dockerFile}":/Dockerfile:ro redcoolbeans/dockerlint
# Fix issue with errors with comments before FROM. If # doesn't have a whitespace after it. Needs to have space or tab.
# It is splitting on [ \t] then testing first item, instead of testing first char in line.
# Might also have issues with comments on same line as instructions. Need to test
# -p to treat warnings as errors
