#!/bin/bash
#
# Dockerfile testing
#
# Known test programs:
#  dockerfile-lint         https://github.com/projectatomic/dockerfile_lint
#    - This should be run on Dockerfile and image with different rule sets
#  dockerfile-validator
#  dockerlint              https://github.com/redcoolbeans/dockerlint
#  hadolint
#  lynis
#  validate-dockerfile
#  whale-linter

printf "=%.s" {1..30}
echo -e "\nStarting Dockerfile testing..."
printf "=%.s" {1..30}
echo

# TODO: setup for all scripts or put in seperate file and source in each ?
tmpdir=tmp
dockerDir=.
reportsDir=reports
if [ -n "${dockerfilePath}" ]; then
  # Support passing in Dockerfile path by env variable
  dockerFile=${dockerfilePath}
else
  dockerFile=${dockerDir}/Dockerfile
fi

mkdir -p ${tmpdir}
mkdir -p ${reportsDir}

static-analysis-dockerfile-dockerlint.sh
static-analysis-dockerfile-lynis.sh
static-analysis-dockerfile-lint.sh
static-analysis-dockerfile-whale-linter.sh

printf "=%.s" {1..30}
echo -e "\nFinished Dockerfile testing."
printf "=%.s" {1..30}
echo
