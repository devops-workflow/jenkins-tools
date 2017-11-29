#!/bin/bash
#
# Setup terraform remote backend using AWS S3 and DynamoDB
#
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

org=$1
org="${org,,}"
envDeploy=$2
envDeploy="${envDeploy,,}"
service=$3
service="${service,,}"

cd infrastructure/terraform

terraform --version
terraform init \
  -input=false ${upgrade} \
  -backend-config "bucket=${org}-${envDeploy}-tf" \
  -backend-config "key=services/${service}.tfstate" \
  -backend-config "dynamodb_table=tf-state-lock" \
  -backend-config "region=${aws_region}"
  #-backend-config "encrypt=true"

  # kms_key_id=${kms_key_id}
  # profile=${aws_profile}
