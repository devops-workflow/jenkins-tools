#!/bin/bash
#
# Setup terraform remote backend using AWS S3 and DynamoDB
#
# Environment Variables:
#   TERRAFORM_CMD   Set the command used to run terraform

# TODO: need routines to create (setup in terraform):
#   s3 bucket
#   dynamodb table w/ primary key: LockID
#
# TODO: verify AWS access
#

#TODO: make arg
aws_region='us-west-2'

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <org namespace> <deploy env> <service> [upgrade]"
  exit 1
fi
#echo "Usage: $0 <org namespace> <deploy env> <service> <kms id>"
if [ "$#" -eq 4 -a "$4" = "upgrade" ]; then
  upgrade="-upgrade"
fi
if [ -n  "${TERRAFORM_CMD}" ]; then
  tf_cmd="${TERRAFORM_CMD}"
else
  tf_cmd="terraform"
fi

org=$1
org="${org,,}"
envDeploy=$2
envDeploy="${envDeploy,,}"
service=$3
service="${service,,}"

cd infrastructure/terraform
tf_bucket="bucket=${org}-${envDeploy}-tf"
tf_key="key=services/${service}.tfstate"
tf_table="dynamodb_table=tf-state-lock"
tf_region="region=${aws_region}"

echo -e "Terraform backend:\n\t${tf_bucket}\n\t${tf_key}\n\t${tf_table}\n\t${tf_region}"
${tf_cmd} --version
${tf_cmd} init \
  -input=false ${upgrade} \
  -backend-config "${tf_bucket}" \
  -backend-config "${tf_key}" \
  -backend-config "${tf_table}" \
  -backend-config "${tf_region}"
  #-backend-config "encrypt=true"

  # kms_key_id=${kms_key_id}
  # profile=${aws_profile}
