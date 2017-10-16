#!/bin/bash
#
tmpdir=${WORKSPACE}/tmp
cmdArgs=$(cat ${tmpdir}/dockerBuildArgsVars)
cmdTags=$(cat ${tmpdir}/dockerBuildArgsTags)
#cmdArgs=$(cat ${tmpdir}/dockerBuildArgs)
dockerDir=$(cat ${tmpdir}/dockerDir)

### Build: docker image
docker build ${cmdTags} ${cmdArgs} -f ${dockerDir}/Dockerfile.
