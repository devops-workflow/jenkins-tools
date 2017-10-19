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

# Figure out compose filename
composeFiles=$(ls ${swarmDir}/*.${ENV}.yml)
if [ $? -ne 0 ]; then
  echo "ERROR: No Swarm compose file found for environment: ${ENV}"
  exit 2
elif [ $(echo ${composeFiles} | awk '{print NF}') -eq 1 ]; then
  swarmFile=${composeFiles}
else
  echo "ERROR: Only 1 swarm compose file allowed per environment"
  exit 2
fi
#if [ -f ${swarmDir}/${IMAGE}.${ENV}.yml ]; then
#  swarmFile=${swarmDir}/${IMAGE}.${ENV}.yml
#elif [ -f ${swarmDir}/${IMAGE}.yml ]; then
#  swarmFile=${swarmDir}/${IMAGE}.yml
#else
#  echo "ERROR: No Swarm compose file found"
#fi

# Get swarm stack name
swarmFilename="${swarmFile##*/}"
STACK_NAME="${swarmFilename%%.*}"
if [ -z "${STACK_NAME}" -o "${STACK_NAME}" == "${swarmFilename}" ]; then
  echo "ERROR: No stack name found. Using app name."
  STACK_NAME=${IMAGE}
#elif [ "${STACK_NAME}" == "${ENV}" ]; then
#  echo "ERROR: Got environment name for stack name. Not allowed"
#  exit 3
fi

echo "Deploying to swarm cluster: ${ENV} ..."
echo "Deploying as stack: ${STACK_NAME}"
echo "Using compose file: ${swarmFile}"
docker --version
#aws_login=$(aws ecr get-login --region ${AWS_DEFAULT_REGION})
#docker stack deploy --with-registry-auth -c ${swarmFile} ${STACK_NAME}
echo "Deploy CMD: docker stack deploy -c ${swarmFile} ${STACK_NAME}"
docker stack deploy -c ${swarmFile} ${STACK_NAME}
echo "Exit code: $?"
