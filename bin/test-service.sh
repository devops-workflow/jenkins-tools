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
# Commit message can be multiple lines
gitCommitMsg=$(git log -1 --pretty=%B | tr -d '\r' | tr '\n' ';')

data="{\"service\":\"${service}\", \"gitCommit\":\"${GIT_COMMIT}\", \"commitedBy\":\"${GIT_COMMITTER_NAME}\", \"commitMessage\":\"${gitCommitMsg}\", \"jenkinsBuildId\":\"${BUILD_ID}\", \"user\":\"jenkins\"}"
echo "Data sending to TAS: ${data}"

# Change --data to --data-urlencode ? Test may not work
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
