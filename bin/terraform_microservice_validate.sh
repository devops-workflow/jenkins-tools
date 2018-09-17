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

tfvarsFile () {
  env=$1
  if [ "$#" -eq 2 ]; then
    file="${env}-$2.tfvars"
  else
    file="${env}.tfvars"
  fi
  if [ -f ${file} ]; then
    echo "-var-file=${file}"
  else
    echo ""
  fi
  return
}

if [ "$#" -lt 2 -o "$#" -gt 3 ]; then
  echo "Usage: $0 <dir> <deploy env> [<modifier>]"
  exit 1
fi
dir=$1
envDeploy=$2
envDeploy="${envDeploy,,}"
if [ "$#" -gt 2 ]; then
  modifier=$3
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
arg_var_file=$(tfvarsFile ${envDeploy} ${modifier})
#terraform init -input=false
# or terraform-init-s3-service.sh $org $env $service
${tf_cmd} get
echo "Validate..."
${tf_cmd} validate ${arg_var_file}
