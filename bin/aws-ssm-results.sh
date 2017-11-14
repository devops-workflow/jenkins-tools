#!/bin/bash
#
# Get SSM command results
#
#  ssmId=$(echo "${{ssmResults}}" | jq -r .Command.CommandId)
#
# TODO: handle multiple results returned - Needs testing

ssmId=$1
status='Pending'
while [ "${status}" = "Pending" -o "${status}" = "InProgress" -o "${status}" = "Delayed" ]; do
  sleep 1
  ssmResult=$(aws ssm list-commands --command-id ${ssmId})
  status=$(echo "${ssmResult}" | jq -r .Commands[].Status | sort -u)
  echo "DEBUG: Status in loop: '${status}'"
  statusTypes=$(echo "${status}" | wc -l)
  if [ $statusTypes -gt 1 ]; then
    echo -e "\tDEBUG: resetting status. Had ${statusTypes} status types"
    status='InProgress'
  fi
done
if [ "${status}" = "null" ]; then
  echo "DEBUG: status null"
  echo "${ssmResult}" | jq .
fi
case ${status} in
  Canceled)
    echo "ERROR: SSM Aborted"
    ;;
  Failed|Undeliverable|Terminated)
    echo "ERROR: SSM Failed"
    # TODO: output more details
    ;;
  *)
    echo "SSM completed with status: ${status}"
    ;;
esac
