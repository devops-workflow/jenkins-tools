#!/bin/bash
#
# Terraform plan/apply for Microservices
#
# Environment variables used:
#   KMS_S3_BUCKET NAMESPACES
# Arguments:
#   tfCmd, env, kmsKey

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}
#nonNamespaced=(QA Staging Prod)
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <plan|apply> <deploy env>"
  #echo "Usage: $0 <plan|apply> <deploy env> <KMS Key>"
  exit 1
fi
tfCmd=$1
envDeploy=$2
envDeploy="${envDeploy,,}"
#kmsKey=$3
#containsElement ${envApp} "${nonNamespaced[@]}"
tfDir="terraform"
case ${tfCmd} in
  apply)
    opts="tfplan"
    init_upgrade="-upgrade"
    # upgrade updates modules, plugins (providers),
    get_update=""
    ;;
  plan)
    opts="-out=tfplan"
    init_upgrade="-upgrade"
    get_update="" # "-update"
    ;;
  *)
    echo "ERROR: unknown command: ${tfCmd}"
    exit 1
    ;;
esac

# TODO: plan and apply jobs should share workspace
#   or rewrite plan to fix absolute paths

# Setup PyEnv/Virtualenv and active needed environment
#. source-python-virtual-env.sh
#pyenv activate aws-cli
### Get runtime config and secrets here if needed
# Get settings and creds from KMS
#. kms_pull_and_export.sh ${KMS_S3_BUCKET} ${NAMESPACES}
export TF_IN_AUTOMATION=true
set -x
terraform --version
cd ${WORKSPACE}/infrastructure/${tfDir}
echo "Setting up terraform ..."
terraform init -input=false ${init_upgrade}
# or ./deploy.sh
# or terraform-init-s3-service.sh $org $env $service
terraform get ${get_update}
echo "Running terraform ${tfCmd}..."
terraform ${tfCmd} -input=false -var "env=${envDeploy}"

#tfVarFile=infrastructure/${tfDir}/${env}.vars -P tfAction=${tfCmd} -P tfConfS3KmsKey=${kmsKey} terraform
