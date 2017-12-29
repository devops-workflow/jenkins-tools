#!/bin/bash
#
# Get the name of the service stack to deploy
#
#
# Get stack name
dirTerraform="infrastructure/terraform"

if [ -d "${dirTerraform}" ]; then
  pushd ${dirTerraform}
  files=$(ls -1 *.tf | grep -vE '(provider|terraform|variables).tf' )
  if [ $(echo "$files" | wc -l) -eq 1 ]; then
    microservice_stack="${files%%.tf}"
  else
    echo "ERROR: No terraform file found to get stack name from"
    exit 1
  fi
  popd
fi
