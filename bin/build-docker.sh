#!/bin/bash
#
tmpdir=${WORKSPACE}/tmp
cmdArgs=$(cat ${tmpdir}/dockerBuildArgsVars)
cmdTags=$(cat ${tmpdir}/dockerBuildArgsTags)
#cmdArgs=$(cat ${tmpdir}/dockerBuildArgs)
dockerDir=$(cat ${tmpdir}/dockerDir)

### Build: docker image
echo "Build CMD: docker build ${cmdTags} ${cmdArgs} -f ${dockerDir}/Dockerfile ."
docker build ${cmdTags} ${cmdArgs} -f ${dockerDir}/Dockerfile .
exitCode=$?
if [ ${exitCode} -ne 0 ]; then
  echo "ERROR: docker build failed!! Exit code: ${exitCode}"
  exit 1
fi
