#!/bin/bash
#
# Deploy docker image to swarm cluster
#
# This is designed to run under Jenkins
#
tmpdir=${WORKSPACE}/tmp
dockerDir=$(cat ${tmpdir}/dockerDir)

# Get vars & export
tmp="${JOB_NAME%+*}"
ENV="${tmp##*+}"
export ENV="${ENV,,}"
IMAGE=$(${tmpdir}/dockerImageName)
export NAMESPACE="${IMAGE%/*}"
export IMAGE="${IMAGE#*/}"
export VERSION=$(cat ${tmpdir}/version)
swarmDir=infrastructure/swarm

if [ -f ${swarmDir}/${IMAGE}.${ENV}.yml ]; then
  swarmFile=${swarmDir}/${IMAGE}.${ENV}.yml
elif [ -f ${swarmDir}/${IMAGE}.yml ]; then
  swarmFile=${swarmDir}/${IMAGE}.yml
else
  echo "ERROR: No Swarm compose file found"
fi

echo "Deploying to swarm cluster: ${ENV} ..."
aws_login=$(aws ecr get-login --region ${AWS_DEFAULT_REGION})
docker stack deploy --with-registry-auth -c ${swarmFile} ${IMAGE}
