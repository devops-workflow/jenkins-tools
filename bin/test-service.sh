#!/bin/bash
#
# Trigger automated test service
#

if [ "TEST" == "$1" ]; then
  GIT_URL="https://github.com/WisePricer/proxy-service.git"
  GIT_COMMIT="xxxxxxx"
  GIT_COMMITTER_NAME="Steven"
  BUILD_ID=1
fi

header="Content-Type: application/json"
repo=$(basename ${GIT_URL})
service="${repo%%.*}"
gitCommitMsg=$(git log -1 --pretty=%B)

data="{\"service\":\"${service}\", \"gitCommit\":\"${GIT_COMMIT}\", \"commitedBy\":\"${GIT_COMMITTER_NAME}\", \"commitMessage\":\"${gitCommitMsg}\", \"jenkinsBuildId\":\"${BUILD_ID}\", \"user\":\"jenkins\"}"
echo "Data sending to TAS: ${data}"

curl -fiSs --header "${header}" \
--data "{\"service\":\"${service}\", \"gitCommit\":\"${GIT_COMMIT}\", \"commitedBy\":\"${GIT_COMMITTER_NAME}\", \"commitMessage\":\"${gitCommitMsg}\", \"jenkinsBuildId\":\"${BUILD_ID}\", \"user\":\"jenkins\"}" \
http://tas.test.wiser.com:3060/test_deployed_service
result=$?
if [ $result -ne 0 ]; then
  echo -e "\nERROR: curl command failed. Result: ${result}"
  exit ${result}
else
  echo -e "\n"
fi

#--data "{\"service\":\"${service}\", \"gitCommit\":\"${GIT_COMMIT}\", \"commitedBy\":\"${GIT_COMMITTER_NAME}\", \"commitMessage\":\"${gitCommitMsg}\", \"JenkinsBuildId\":\"${BUILD_ID}\", \"user\":\"jenkins\"}" \
