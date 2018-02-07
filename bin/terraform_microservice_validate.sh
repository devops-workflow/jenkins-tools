#!/bin/bash
#
# Terraform validate for Microservices
#
# Environment Variables:
#   TERRAFORM_CMD   Set the command used to run terraform
#   WORKSPACE
# Arguments:
#

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

if [ 1 -eq 2 ]; then
  nonNamespaced=(QA Staging Prod)
  if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dir> <app env>"
    exit 1
  fi
  dir=$1
  envApp=$2
  echo "DEBUG: Got dir=${dir}, EnvApp=${envApp}"
  containsElement ${envApp} "${nonNamespaced[@]}"
  if [ $? -ne 0 ]; then
    tfDir="terraform-ns"
  else
    tfDir="terraform"
  fi
fi

dir="."
tfDir="terraform"
if [ -n  "${TERRAFORM_CMD}" ]; then
  tf_cmd="${TERRAFORM_CMD}"
else
  tf_cmd="terraform"
fi

#terraform --version
cd ${WORKSPACE}/${dir}/infrastructure/${tfDir}
echo "Setting up terraform ..."
#terraform init -input=false
# or terraform-init-s3-service.sh $org $env $service
${tf_cmd} get
echo "Validate..."
${tf_cmd} validate
