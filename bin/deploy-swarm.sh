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
if [ -z "${VERSION}" ]; then
  # If no version specified.
  echo "ERROR: Docker image version is required!!!"
  exit 1
fi

if [ -f ${swarmDir}/${IMAGE}.${ENV}.yml ]; then
  swarmFile=${swarmDir}/${IMAGE}.${ENV}.yml
elif [ -f ${swarmDir}/${IMAGE}.yml ]; then
  swarmFile=${swarmDir}/${IMAGE}.yml
else
  echo "ERROR: No Swarm compose file found"
fi

if [ -f ${swarmDir}/STACK_NAME ]; then
  STACK_NAME=$(cat ${swarmDir}/STACK_NAME)
else
  echo "WARNING: No stack name defined. Using app name."
  STACK_NAME=${IMAGE}
fi

echo "Deploying to swarm cluster: ${ENV} ..."
echo "Deploying as stack: ${STACK_NAME}"
echo "Using compose file: ${swarmFile}"
docker --version
aws_login=$(aws ecr get-login --region ${AWS_DEFAULT_REGION})
docker stack deploy --with-registry-auth -c ${swarmFile} ${STACK_NAME}
