#!/bin/bash
#
# Deploy docker image to swarm cluster
#
# This is designed to run under Jenkins
#
tmpdir=${WORKSPACE}/tmp
swarmDir=infrastructure/swarm

# Get vars & export
tmp="${JOB_NAME%+*}"
ENV="${tmp##*+}"
export ENV="${ENV,,}"
NAMESPACE="${JOB_NAME%%+*}"
export NAMESPACE="${NAMESPACE,,}"
tmp="${JOB_NAME#*+}"
export IMAGE="${tmp%%+*}"
if [ -n "$(git tag)" ]; then
  VERSION=$(git describe --tags)
else
  VERSION="0.0.0-$(git rev-list HEAD --count)-$(git rev-parse --short HEAD)"
fi
export VERSION

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
