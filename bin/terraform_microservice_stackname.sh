#!/bin/bash
#
# Get the name of the service stack to deploy
#
#
# Get stack name
dirTerraform="infrastructure/terraform"

pushd ${dirTerraform}
files=$(ls -1 *.tf | grep -vE (provider|terraform|variables).tf)
if [ $(echo "$files" | wc -l) -eq 1 ]; then
  microservice_stack="${files%%.tf}"
else
  echo "ERROR: "
  exit 1
fi
popd
