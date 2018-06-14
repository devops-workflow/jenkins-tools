#!/bin/bash
#
# Get SSM command results
#
#  ssmId=$(echo "${{ssmResults}}" | jq -r .Command.CommandId)
#
# TODO: handle multiple results returned - Needs testing

ssmId=$1
service=$2
status='Pending'
while [ "${status}" = "Pending" -o "${status}" = "InProgress" -o "${status}" = "Delayed" ]; do
  sleep 1
  ssmResult=$(aws ssm list-commands --command-id ${ssmId})
  status=$(echo "${ssmResult}" | jq -r .Commands[].Status | sort -u)
  echo "DEBUG: ${service}: Status in loop: '${status}'"
  statusTypes=$(echo "${status}" | wc -l)
  if [ $statusTypes -gt 1 ]; then
    echo -e "\tDEBUG: ${service}: resetting status. Had ${statusTypes} status types"
    status='InProgress'
  fi
done
if [ "${status}" = "null" ]; then
  echo "DEBUG: ${service}: status null"
  echo "${ssmResult}" | jq .
fi
case ${status} in
  Canceled)
    echo "ERROR: ${service}: SSM Aborted"
    ;;
  Failed|Undeliverable|Terminated)
    echo "ERROR: ${service}: SSM Failed"
    # TODO: output more details
    echo "DEBUG: ${service}: list-commands..."
    echo "${ssmResult}" | jq -r .
    echo "DEBUG: ${service}: list-command-invocations..."
    aws ssm list-command-invocations --command-id ${ssmId} --details
    ;;
  *)
    echo "${service}: SSM completed with status: ${status}"
    echo "DEBUG: ${service}: list-commands..."
    echo "${ssmResult}" | jq .
    echo "DEBUG: ${service}: list-command-invocations..."
    aws ssm list-command-invocations --command-id ${ssmId} --details
    ;;
esac
