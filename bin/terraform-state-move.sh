#!/bin/bash
#
# Move/rename terraform state file in AWS S3 and lock key in DynamoDB
#
# Args:
#   s3Bucket newPath oldPaths

org='wiser'
env="${TF_VAR_env}"
serviceNameOld="${microservice_stack}"
serviceNameNew="${DOCKER_IMAGE_NAME}"

tfStatePathsOld="${serviceNameOld}/terraform.tfstate services/${serviceNameOld}.tfstate"
tfStatePathNew="services/${serviceNameNew}.tfstate"
s3Bucket="${org}-${env}-tf"

#s3Bucket=$1
#tfStatePathNew=$2
#tfStatePathsOld="${*:3}"
localTerraformCacheDir='infrastructure/terraform/.terraform'

tf_state_mv() {
  local s3Bucket=$1
  local tfStateOld="${s3Bucket}/$2"
  local tfStateNew="${s3Bucket}/$3"
  if [ "${tfStateOld}" = "${tfStateNew}" ]; then
    echo "INFO: Old and New state paths are the same - skipping terraform state move"
  elif [ $(aws s3 ls s3://${tfStateOld} | wc -l) -eq 1 ]; then
    echo "INFO: Moving terraform state..."
    aws s3 mv s3://${tfStateOld} s3://${tfStateNew}
    md5=$(aws dynamodb get-item --table-name tf-state-lock --key "{ \"LockID\":{\"S\":\"${tfStateOld}-md5\"} }" --projection-expression "Digest" | jq -r .Item.Digest.S)
    if [ -n "${{md5}}" ]; then
      echo "INFO: Moving DynamoDB key..."
      aws dynamodb put-item --table-name tf-state-lock --item "{ \"LockID\":{\"S\":\"${tfStateNew}-md5\"}, \"Digest\":{\"S\":\"${md5}\"} }"
      aws dynamodb delete-item --table-name tf-state-lock --key "{ \"LockID\":{\"S\":\"${tfStateOld}-md5\"} }"
    fi
    rm -rf ${localTerraformCacheDir}
  fi
}

for tfStateOld in ${tfStatePathsOld}; do
  tf_state_mv ${s3Bucket} ${tfStateOld} ${tfStatePathNew}
done
