#!/bin/bash
#
# Trigger automated test service
#

header="Content-Type: application/json"
repo=$(basename ${GIT_URL})
service="${repo%%.*}"
gitCommitMsg=$(git log -1 --pretty=%B)

curl --header "${header}" \
--data "{\"service\":\"${service}\", \"gitCommit\":\"${GIT_COMMIT}\", \"commitedBy\":\"${GIT_COMMITTER_NAME}\", \"commitMessage\":\"${gitCommitMsg}\", \"JenkinsBuildId\":\"${BUILD_ID}\", \"user\":\"jenkins\"}" \
http://tas.test.wiser.com:3060/test_deployed_service
