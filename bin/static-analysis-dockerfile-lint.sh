#!/bin/bash
#
# Dockerfile testing
#
#  dockerfile-lint         https://github.com/projectatomic/dockerfile_lint
#    - This should be run on Dockerfile and image with different rule sets

tmpdir=tmp
dockerDir=.
configDir="${NODE_HOME}/etc"
reportsDir=reports
jqDir="${configDir}/jq"
rulesDir="${configDir}/dockerfile-lint"
if [ -n "${dockerfilePath}" ]; then
  # Support passing in Dockerfile path by env variable
  dockerFile=${dockerfilePath}
else
  dockerFile=${dockerDir}/Dockerfile
fi

mkdir -p ${tmpdir}
mkdir -p ${reportsDir}

###
### dockerfile-lint
###
# Setup rule set
# TODO: customize this for us. Test for all labels that we require
# ${rulesDir}/rules-dockerfile-org.label-schema.yaml

ruleFile="rules-dockerfile-lint.yaml"

# Create jq parser for creating Jenkins Warning plugin output
parserFile="${jqDir}/parse-dockerfile-lint.jq"

printf "=%.s" {1..3}
echo "Running dockerfile-lint..."
#docker run -i --rm --privileged projectatomic/dockerfile-lint dockerfile_lint -h
# No version available from app or image tags
# Rules need to be in volume. cp to tmp and reference there
cp ${rulesDir}/rules-dockerfile-*.yaml ${tmpdir}
docker run -i --rm --privileged -v `pwd`:/root/ -v /var/run/docker.sock:/var/run/docker.sock projectatomic/dockerfile-lint dockerfile_lint -p -r ${tmpdir}/${ruleFile} -f ${dockerFile}
docker run -i --rm --privileged -v `pwd`:/root/ -v /var/run/docker.sock:/var/run/docker.sock projectatomic/dockerfile-lint dockerfile_lint -p -j -r ${tmpdir}/${ruleFile} -f ${dockerFile} > ${reportsDir}/dockerfile-lint-dockerfile.json
# Running this on the results image returns almost same results
# use -j to get json output
# Can get data from json with jq
# jq '.error.count' ${reportsDir}/dockerfile-lint-dockerfile.json
# jq '.warn.count' ${reportsDir}/dockerfile-lint-dockerfile.json
# jq '.info.count' ${reportsDir}/dockerfile-lint-dockerfile.json
# jq '.error.data[].message' ${reportsDir}/dockerfile-lint-dockerfile.json
jq --arg file ${dockerFile} -f ${parserFile} ${reportsDir}/dockerfile-lint-dockerfile.json > ${reportsDir}/dockerfile-lint-dockerfile.warnings
if [ ! -s ${reportsDir}/dockerfile-lint-dockerfile.warnings ]; then
  rm -f ${reportsDir}/dockerfile-lint-dockerfile.warnings
fi
