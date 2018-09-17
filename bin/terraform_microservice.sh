#!/bin/bash
#
# Terraform plan/apply for Microservices
#
# Environment Variables:
#   TERRAFORM_CMD   Set the command used to run terraform
#   KMS_S3_BUCKET
#   NAMESPACES
# Arguments:
#   tfCmd, env, kmsKey

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}
#nonNamespaced=(QA Staging Prod)

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
  echo "Usage: $0 <plan|apply|destroy> <deploy env> [<modifier>]"
#if [ "$#" -ne 2 ]; then
#  echo "Usage: $0 <plan|apply|destroy> <deploy env>"
  #echo "Usage: $0 <plan|apply> <deploy env> <KMS Key>"
  exit 1
fi
if [ -n  "${TERRAFORM_CMD}" ]; then
  tf_cmd="${TERRAFORM_CMD}"
else
  tf_cmd="terraform"
fi
tfCmd=$1
envDeploy=$2
envDeploy="${envDeploy,,}"
if [ "$#" -gt 2 ]; then
  modifier=$3
fi
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
  destroy)
    opts="-force"
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
set +x
${tf_cmd} --version
cd ${WORKSPACE}/infrastructure/${tfDir}
echo "Setting up terraform ..."
arg_var_file=$(tfvarsFile ${envDeploy} ${modifier})
#terraform init -input=false ${init_upgrade}
# or ./deploy.sh
# or terraform-init-s3-service.sh $org $env $service
${tf_cmd} get ${get_update}
echo "Running terraform ${tfCmd}..."
${tf_cmd} ${tfCmd} -input=false -no-color ${arg_var_file} ${opts}

#tfVarFile=infrastructure/${tfDir}/${env}.vars -P tfAction=${tfCmd} -P tfConfS3KmsKey=${kmsKey} terraform
